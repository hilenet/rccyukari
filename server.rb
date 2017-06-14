require_relative 'src/init.rb'
require_relative 'src/adopt_db.rb'
require_relative 'src/speak_task.rb'

=begin
Thread.start do

end
=end


class Server < Sinatra::Base
  set :server, 'thin'
  set :sockets, []
  tasks = []

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  get '/' do
    erb :index
  end

  get '/ws' do
    redirect to '/' unless request.websocket?

    request.websocket do |ws|
      ws.onopen do
        puts "open from #{request.ip}"
        settings.sockets << ws
        openWebsock(ws)
      end
      ws.onmessage do |msg|
        puts "get message: #{msg}"
        getMessage msg, request.ip
      end
      ws.onclose do
        settings.sockets.delete ws
      end
    end
  end

  private

  def openWebsock ws
    Log.last(50).reverse do |node|
      ws.send recordTohash(node).to_json
    end
  end

  def getMessage text, ip
    speaktask = SpeakTask.new text, ip 
    return unless speaktask!=nil

    settings.sockets.each do |s|
      s.send(recordToHash(Log.last).to_json)
    end
  end

  def recordToHash record
    hash = {time: record.created_at.localtime.to_s[0..-7],
            text: record.text}
  end

end
