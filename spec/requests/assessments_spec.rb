require 'rails_helper'

RSpec.describe 'Assessments', type: :request do
  let(:user) { create(:user) }
  let(:employee) { create(:employee, company: user.company) }

  before { sign_in_as user }

  # Counts every statement the page runs, cached ones included: a per-row query that repeats
  # hides behind the query cache otherwise.
  def statements_during
    count = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      count += 1 unless payload[:name] == 'SCHEMA'
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it 'runs the same statements for one row as for a full page' do
    create(:assessment, employee:)
    with_one = statements_during { get root_path }

    49.times { create(:assessment, employee:) }
    with_fifty = statements_during { get root_path }

    expect(response).to have_http_status :ok
    expect(with_fifty).to eq with_one
  end
end
