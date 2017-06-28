require 'json'
require 'sinatra/base'
require 'sinatra-websocket'

require_relative 'src/adapt_db'
require_relative 'src/speak_integrate'

class Server < Sinatra::Base
  set :server, 'thin'
  set :sockets, []
  @@youtube = nil
  @@youtube_title = "-"
  
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
      ws.onmessage do |json|
        $sIntegrate.checkTask()
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

  # proc of message getting
  def getMessage text, char, ip
    speaktask = $sIntegrate.publishTask text, char, ip
    
    if speaktask!=nil
      multiCast({"log": recordToHash(Log.last)}.to_json)
    end

    return speaktask
  end

  private

  # hash
  def multiCast msg
    settings.sockets.each do |s|
      s.send(msg)
    end
  end

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

    return false unless url.match /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/
    
    command = "youtube-dl '#{url}' -o - | mplayer - -novideo --volume=40"

    @@youtube = Process.spawn("echo \"#{command}\"") if $DEV
    @@youtube = Process.spawn(command, {pgroup: true}) if !$DEV

    @@youtube_title = titleOf(url)
    multiCast({"youtube": @@youtube_title}.to_json)
  end

  def titleOf url
    conn = Faraday.new(url: url) do |builder|
      builder.request  :url_encoded
      builder.response :logger
      builder.adapter  :net_http
    end
    
    res = conn.get()
    
    q = res.body.match /<meta property="og:title" content="(.*)">/
    text = q[1]

    return text.force_encoding('UTF-8')
  end

  def killYoutube 
    return unless @@youtube

    isAlive = !Process.waitpid(@@youtube, Process::WNOHANG) 
    Process.kill 9, -1*@@youtube if isAlive
    Process.waitpid(@@youtube, Process::WNOHANG) if isAlive

    @@youtube = nil
    @@youtube_title = "-"
    multiCast({"youtube": @@youtube_title}.to_json)
  end

  # kill all speak task
  def silentize
    $sIntegrate.clearTasks
    killYoutube()
  end

  # send initialize log when ws.open
  def openWebsock ws
    Log.last(50).each do |node|
      ws.send({"log": recordToHash(node)}.to_json)
    end
    ws.send({"youtube": @@youtube_title}.to_json)
  end

  # convert log obj to rb hash
  def recordToHash record
    hash = {time: record.created_at.localtime.to_s[0..-7],
            text: record.text}
  end

end
