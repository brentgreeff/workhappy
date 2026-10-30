# Mail goes out via deliver_later; under the :test queue adapter the job is only
# enqueued, so without this a system spec that opens an email finds nothing.
RSpec.configure do |config|
  config.include ActiveJob::TestHelper, type: :system

  config.around(:each, type: :system) do |example|
    perform_enqueued_jobs { example.run }
  end
end
