Rails.application.config.middleware.use OmniAuth::Builder do

  provider :salesforce, ENV['CLIENT_ID'], ENV['CLIENT_SECRET']

end
