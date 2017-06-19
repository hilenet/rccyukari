require 'yaml'
require 'twitter'

Thread.abort_on_exception = true

tw = Thread.new do 
  auth = YAML.load_file('config/auth.yml')["twitter"]
  cl = Twitter::Streaming::Client.new do |config|
    config.consumer_key = auth["ck"]
    config.consumer_secret = auth["cs"]
    config.access_token = auth["at"]
    config.access_token_secret = auth["as"]
  end
  print "thread established"
  cl.filter(track: "#rccyukari") do |status|
    next unless status.is_a? Twitter::Tweet
    text = status.text.dup
    next if text.start_with? "RT"
    text.gsub!("#rccyukari", "")
    puts "tw: #{text}"
    if text.include? "#幼女" 
      text.gsub!("#幼女", "")
      $sIntegrate.publishTask text, "ai", status.user.screen_name
    else 
      $sIntegrate.publishTask text, status.user.screen_name
    end
  end
  print "twitter thread: something happen"
end
