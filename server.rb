require 'yaml'
require 'json'
require 'sinatra/base'
require 'sinatra-websocket'

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
  @@tasks = []
  @@youtube = nil

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  get '/' do
    erb :index
  end

  get '/ws' do
    checkTask()
    redirect to '/' unless request.websocket?

    request.websocket do |ws|
      ws.onopen do
        puts "open from #{request.ip}"
        settings.sockets << ws
        openWebsock(ws)
      end
      ws.onmessage do |json|
        puts "get message: #{json}"

        hash = JSON.parse json
        silentize();next if(hash["silent"]!=nil)
        getMessage(hash["msg"], request.ip);next if (hash["msg"]!=nil)
        getYoutube(hash["youtube"], request.ip);next if (hash["youtube"]!=nil)
      end
      ws.onclose do
        settings.sockets.delete ws
      end
    end
  end

  private

  # play youtube
  def getYoutube url, ip
    killYoutube()
    
    @@youtube = Process.spawn(command, {pgroup: true})

  end

  def killYoutube
    Process.kill 9, -1*@@youtube if @@youtube
  end

  # kill all speak task
  def silentize
    @@tasks.each do |task|
      task.kill
    end
    @@tasks.clear
    killYoutube()
  end

  # check all speak task
  def checkTask
    @@tasks.each do |task|
      @@tasks.delete task unless task.isAlive
    end
  end

  # send initialize log when ws.open
  def openWebsock ws
    Log.last(50).each do |node|
      ws.send recordToHash(node).to_json
    end
  end

  # proc of message getting
  def getMessage text, ip
    speaktask = SpeakTask.new text, ip, @@tasks 
    return unless speaktask!=nil

    settings.sockets.each do |s|
      s.send(recordToHash(Log.last).to_json)
    end

    @@tasks << speaktask if @@tasks
    removeTask @@tasks.shift if @@tasks.length>5
  end

  # remove arg task
  def removeTask task
    task.kill
  end

  # convert log obj to rb hash
  def recordToHash record
    hash = {time: record.created_at.localtime.to_s[0..-7],
            text: record.text}
  end

end
