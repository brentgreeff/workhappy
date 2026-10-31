require 'rails_helper'
require 'rake'

RSpec.describe 'assessments rake tasks' do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? }
  after { Rake::Task.tasks.each(&:reenable) }

  # Both tasks used to raise on a fresh database: ljust(nil) and jsonb_each on nothing.
  it 'status_census prints a zero total on an empty table' do
    expect { Rake::Task['assessments:status_census'].invoke }.to output(/^total\s+0$/).to_stdout
  end

  it 'responses_census prints a zero summary on an empty table' do
    expect { Rake::Task['assessments:responses_census'].invoke }.to output(/^total 0, /).to_stdout
  end

  it 'prints one line per status and one per key on seeded data' do
    employee = create(:employee)
    create(:assessment, employee:, status: 'comp', responses_json: { 'posture' => '4' })

    expect { Rake::Task['assessments:status_census'].invoke }.to output(/^"comp"\s+1$/).to_stdout
    expect { Rake::Task['assessments:responses_census'].invoke }.to output(/^posture\s+string 1, missing 0$/).to_stdout
  end
end
