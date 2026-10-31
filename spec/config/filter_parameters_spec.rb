require 'rails_helper'

RSpec.describe 'filter_parameters' do
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

  it 'keeps answers, free text and identifiers out of the request log, leaves the status visible' do
    filtered = filter.filter(
      'status' => 'done',
      'employee_email' => 'amara@harbour.example',
      'responses_json' => { 'posture' => 4, 'comments' => 'Call me on 07700 900123' },
      'password' => 'secret'
    )

    expect(filtered['status']).to eq 'done'
    expect(filtered.values_at('employee_email', 'responses_json', 'password')).to all(eq '[FILTERED]')
  end
end
