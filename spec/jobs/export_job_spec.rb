require 'rails_helper'

RSpec.describe ExportJob do
  let(:user) { create(:user) }
  let(:export) { user.company.exports.create!(user:) }

  before { create(:assessment, company: user.company, employee: create(:employee, company: user.company)) }

  context 'when building the file raises with row data in the message' do
    before do
      allow(AssessmentScoring).to receive(:score).and_raise(ArgumentError, 'could not score {"comments" => "Call me on 07700 900123"}')
    end

    it 'still fails the job, with the class name only and the original backtrace' do
      expect { described_class.perform_now(export) }.to raise_error(ExportJob::Failed, 'ArgumentError') do |error|
        expect(error.backtrace.first).not_to include 'export_job.rb'
        expect(error.cause).to be_a ArgumentError
      end
    end

    it 'marks the export failed with the generic message' do
      expect { described_class.perform_now(export) }.to raise_error(ExportJob::Failed)

      expect(export.reload).to have_attributes(status: 'failed', error_message: 'Export failed. Please try again.')
    end
  end
end
