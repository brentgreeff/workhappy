# A row as the old app left it: the raw status string in the legacy column, status_v2 NULL,
# written past the model so no callback or validation runs. The factory is the new write path;
# this is the data the normalisation has to cope with.
module LegacyRows
  def legacy_assessment(employee:, status:, created_at: Time.current, responses_json: nil)
    id = Assessment.insert_all(
      [{ company_id: employee.company_id, employee_id: employee.id, employee_email: employee.email,
         status:, responses_json:, created_at:, updated_at: created_at }],
      returning: [:id]
    ).first['id']
    Assessment.find(id)
  end
end

RSpec.configure do |config|
  config.include LegacyRows
end
