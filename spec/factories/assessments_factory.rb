FactoryBot.define do
  factory :assessment do
    employee
    company { employee.company }
    employee_email { employee.email }
    status { 'completed' }
    responses_json { { 'posture' => 4, 'screen' => 3, 'chair' => 5, 'breaks' => 2, 'comments' => 'All fine' } }
  end
end
