class MyChannel < ApplicationCable::Channel
  def subscribed
    p "Setting Stream"
    stream_from "MyStream"
  end

  def doStuff(data)
    p "Doing stuff"
    begin
    o =  Organization.find(data["context"]["organization"])
    p o

    sClient = Restforce.new :oauth_token => o.token,
        :refresh_token => o.refreshtoken,
        :instance_url => o.instanceurl,
        :api_version => ENV['API_VERSION'], :client_id => ENV['CLIENT_ID'], :client_secret => ENV['CLIENT_SECRET']

    accounts = sClient.query("Select Id, Name from Account Limit 10")

    rescue Exception => e
      ActionCable.server.broadcast "MyStream",
        { :method => 'doStuff', :status => 'error', :message => e.message }
    end
    ActionCable.server.broadcast "MyStream",
      { :method => 'doStuff', :status => 'success', :accounts => accounts }
  end
end
