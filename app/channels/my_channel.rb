class MyChannel < ApplicationCable::Channel
  def subscribed
    p "Setting Stream"
    stream_from "MyStream"
  end

  def doStuff(data)
    p "Doing stuff"
    p data
    ActionCable.server.broadcast "MyStream",
      { :method => 'doStuff', :status => 'success',
        :data => { :message => 'Stuff done !' } }
  end
end
