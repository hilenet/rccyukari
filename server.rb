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
        
        return nil if filter request.ip

        hash = JSON.parse json

        if hash['silent']!=nil
          silentize()
        elsif hash['msg']!=nil
          getMessage hash["msg"], hash["char"], request.ip
        elsif hash['url']!=nil
          getYoutube hash["url"], request.ip
        end
      end
      ws.onclose do
        settings.sockets.delete ws
      end
    end
  end

  get '/banned' do 
    res = "banned:<br>"
    BannedIp.all.map do |node|
      line = "#{node.ip}: ~#{(node.created_at.localtime+3600).to_s[0..-7]}"
      res += line+"<br>"
    end

    return res
  end

  private

  # return false if data invalid
  def filter ip
    # Thread切りたいけどトランザクション怪しいなあ・・・
    update_banned_table(ip)
    return true if BannedIp.all.map{|node| node.ip}.include? ip

    return false
  end

  # expire = 3600s
  # ban : 10req / 10s
  def update_banned_table ip
    # reflesh
    unless (l=BannedIp.where("created_at < ?", Time.now-3600)).empty?
      BannedIp.destroy l.map{|node| node.id}
    end
    # ban
    if Log.where("created_at > ?", Time.now-10).length >= 10
      BannedIp.create(ip: ip) unless BannedIp.find_by(ip: ip)
      puts "ban: #{ip}"
    end
  end

  # play youtube
  def getYoutube url, ip
    killYoutube()
    
    command = "youtube-dl '#{url}' -o - | mplayer - -novideo --volume=30 --softvol"

    @@youtube = Process.spawn("echo \"#{command}\"") if DEV
    @@youtube = Process.spawn(command, {pgroup: true}) if !DEV

  end

  def killYoutube
    return unless @@youtube

    isAlive = !Process.waitpid(@@youtube, Process::WNOHANG) 
    Process.kill 9, -1*@@youtube if isAlive
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
  def getMessage text, char, ip
    speaktask = SpeakTask.new text, char, ip
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
