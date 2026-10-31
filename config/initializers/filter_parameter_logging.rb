# Partial match: :email also covers employee_email and email_address. The assessment keys are
# health data and free text; they must never reach the request log.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :responses_json, :responses, :answer, :comments, :name
]
