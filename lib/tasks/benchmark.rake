# The Task 2 measurement, as scripts anyone can rerun in any schema state. seed_large writes
# (a benchmark tenant). bench and explain measure "before" and "after" by dropping or creating
# the dashboard index inside a transaction that is rolled back, so they leave the schema as they
# found it. None of them may run in production.
namespace :assessments do
  BENCH_TENANT = "Atlas Manufacturing"
  DASHBOARD_INDEX = "index_assessments_on_company_id_and_created_at_and_id"

  SCENARIOS = {
    "page 1, no filter" => {},
    "page 200, no filter" => { page: 200 },
    "one-year window" => { filter: { from_date: "2025-01-01", to_date: "2025-12-31" } },
    "status completed" => { filter: { status: "completed" } }
  }.freeze

  # The index states the explain task compares, each forced inside a rolled-back transaction.
  INDEX_STATES = {
    "without the dashboard index" => "DROP INDEX IF EXISTS #{DASHBOARD_INDEX}",
    "two-column candidate (company_id, created_at)" =>
      "DROP INDEX IF EXISTS #{DASHBOARD_INDEX}; CREATE INDEX bench_candidate ON assessments (company_id, created_at)",
    "the dashboard index (company_id, created_at, id)" =>
      "CREATE INDEX IF NOT EXISTS #{DASHBOARD_INDEX} ON assessments (company_id, created_at, id)"
  }.freeze

  desc "Create the benchmark tenant with N assessments (default 2000000, about four minutes). Dev/test only."
  task :seed_large, [:count] => :environment do |_, args|
    refuse_production!
    count = (args[:count] || 2_000_000).to_i
    company = Company.find_or_create_by!(name: BENCH_TENANT)
    company.users.find_or_create_by!(email_address: "admin@atlas.example") { |u| u.password = "password" }
    DemoData.employees(company)

    if company.assessments.exists?
      puts "#{BENCH_TENANT} already has #{company.assessments.count} assessments; nothing done"
      next
    end

    rng = Random.new(company.id)
    elapsed = elapsed_ms do
      count.step(1, -5_000).each_with_index do |remaining, i|
        Assessment.insert_all(DemoData.assessment_rows(company, count: [5_000, remaining].min, rng:))
        print "\r#{[(i + 1) * 5_000, count].min}/#{count}"
      end
    end
    # VACUUM as well as ANALYZE: a fresh bulk load has no visibility map, and without it the
    # planner cannot answer a count from an index alone.
    ActiveRecord::Base.connection.execute("VACUUM ANALYZE assessments")
    puts "\n#{count} assessments in #{(elapsed / 1000.0).round(1)}s, vacuumed and analysed"
  end

  desc "Time the dashboard's statements and whole requests before and after the dashboard " \
    "index, in one run, whatever the schema holds. Writes nothing that stays. Dev/test only."
  task :bench, [:company] => :environment do |_, args|
    refuse_production!
    company = Company.find_by!(name: args[:company] || BENCH_TENANT)
    conn = ActiveRecord::Base.connection
    puts "#{company.name}: #{company.assessments.count} assessments"
    puts "Each number is the second of two runs (ms). Request = the whole GET through the app."

    preserving_dashboard_index(conn) do
      signed_in_session(company) do |session|
        { "BEFORE: without the dashboard index" => INDEX_STATES.keys.first,
          "AFTER: with the dashboard index" => INDEX_STATES.keys.last }.each do |heading, state|
          in_index_state(conn, state) do
            puts "\n== #{heading}"
            puts format("%-22s %8s %8s   %8s %8s %8s", "scenario", "count", "page", "request", "db", "views")
            SCENARIOS.each { |label, params| puts bench_row(company, session, label, params) }
          end
        end
      end
    end
  end

  desc "EXPLAIN (ANALYZE, BUFFERS) the count and page statements without the dashboard index, " \
    "with the two-column candidate, and with the dashboard index; each state forced inside a " \
    "rolled-back transaction. Dev/test only."
  task :explain, [:company] => :environment do |_, args|
    refuse_production!
    company = Company.find_by!(name: args[:company] || BENCH_TENANT)
    conn = ActiveRecord::Base.connection
    statements = explain_statements(company)

    preserving_dashboard_index(conn) do
      INDEX_STATES.each_key do |state|
        in_index_state(conn, state) do |build_ms|
          puts "\n== #{state} (schema change took #{build_ms} ms, rolled back after)"
          statements.each { |label, sql| print_plan(conn, label, sql) }
        end
      end
    end
  end

  def refuse_production!
    abort "Refusing to run a benchmark task in production" if Rails.env.production?
  end

  # Read inside the tasks, not at load: the app is not booted when rake files are read.
  def per_page
    AssessmentsController::PER_PAGE
  end

  def elapsed_ms
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
  end

  def second_of_two(&block)
    2.times.map { elapsed_ms(&block) }.last
  end

  # Records whether the dashboard index exists before the block and puts the schema back to
  # exactly that afterwards, whatever happened in between: the transactions below are the
  # mechanism, this is the guarantee, and it runs on an interrupt too.
  def preserving_dashboard_index(conn)
    existed = conn.index_name_exists?(:assessments, DASHBOARD_INDEX)
    puts "dashboard index #{existed ? 'present' : 'absent'} at start; will be left that way"
    yield
  ensure
    present = conn.index_name_exists?(:assessments, DASHBOARD_INDEX)
    if existed && !present
      conn.add_index :assessments, [:company_id, :created_at, :id], algorithm: :concurrently
      puts "\nrestored the dashboard index"
    elsif !existed && present
      conn.remove_index :assessments, name: DASHBOARD_INDEX
      puts "\nremoved the dashboard index again (it was absent at start)"
    end
    conn.remove_index :assessments, name: "bench_candidate" if conn.index_name_exists?(:assessments, "bench_candidate")
    puts "indexes at end: #{conn.indexes(:assessments).map(&:name).join(', ')}"
  end

  # Forces one index state for the block and rolls it back. DDL is transactional in Postgres,
  # so the schema is exactly as it was afterwards. The DROP holds an exclusive lock on the
  # table until the rollback, so nothing else should be using the database meanwhile.
  def in_index_state(conn, state)
    conn.transaction(requires_new: true) do
      build_ms = elapsed_ms { conn.execute(INDEX_STATES.fetch(state)) }
      yield build_ms
      raise ActiveRecord::Rollback
    end
  end

  def bench_row(company, session, label, params)
    scope = AssessmentFilter.new(params.fetch(:filter, {})).apply(company.assessments)
    page = params.fetch(:page, 1)
    count_ms = second_of_two { scope.count }
    page_ms = second_of_two do
      scope.preload(:employee).order(created_at: :desc, id: :desc).offset((page - 1) * per_page).limit(per_page).to_a
    end
    request = request_timing(session, params)
    format("%-22s %8d %8d   %8d %8d %8d", label, count_ms, page_ms, request[:ms], request[:db], request[:views])
  end

  # The same two filters for both tasks, as the count and the page statements with binds
  # inlined, so the plans are of exactly what the dashboard runs.
  def explain_statements(company)
    { "no filter" => {}, "one-year window" => { from_date: "2025-01-01", to_date: "2025-12-31" } }.flat_map do |label, filter|
      scope = AssessmentFilter.new(filter).apply(company.assessments)
      page = scope.order(created_at: :desc, id: :desc).limit(per_page)
      [["count, #{label}", scope.select("COUNT(*)").to_sql], ["page, #{label}", page.to_sql]]
    end
  end

  def print_plan(conn, label, sql)
    plan = 2.times.map { conn.execute("EXPLAIN (ANALYZE, BUFFERS) #{sql}").map { |row| row["QUERY PLAN"] } }.last
    puts "\n-- #{label} (second run)"
    puts plan.map { |line| "   #{line}" }
  end

  # A signed-in integration session, so the request numbers are the whole GET through the app:
  # the same server, db and view times Rails prints in its `Completed` log line. Signs the
  # session cookie directly rather than posting the form, which needs a CSRF token. The one row
  # this writes, the sign-in session, is removed when the block ends.
  def signed_in_session(company)
    record = company.users.first!.sessions.create!(user_agent: "bench", ip_address: "127.0.0.1")
    jar = ActionDispatch::TestRequest.create.cookie_jar
    jar.signed[:session_id] = record.id
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! "localhost"  # development's host authorization blocks the default www.example.com
    session.cookies["session_id"] = jar[:session_id]
    yield session
  ensure
    record&.destroy
  end

  def request_timing(session, params)
    timings = {}
    subscriber = ActiveSupport::Notifications.subscribe("process_action.action_controller") do |event|
      timings = { db: event.payload[:db_runtime].to_f.round, views: event.payload[:view_runtime].to_f.round }
    end
    ms = second_of_two do
      session.get("/", params: params.slice(:filter, :page))
      raise "GET / returned #{session.response.status}" unless session.response.ok?
    end
    timings.merge(ms:)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
