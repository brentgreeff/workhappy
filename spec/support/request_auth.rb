module RequestAuthHelper
  def sign_in_as(user)
    session = user.sessions.create!(user_agent: 'rspec', ip_address: '127.0.0.1')
    jar = ActionDispatch::TestRequest.create.cookie_jar
    jar.signed[:session_id] = session.id
    cookies[:session_id] = jar[:session_id]
  end
end

RSpec.configure do |config|
  config.include RequestAuthHelper, type: :request
end
