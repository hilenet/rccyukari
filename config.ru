require 'bundler'
Bundler.require(ENV['RACK_ENV'])

File.open 'pid', 'w' do |f|
  f.write Process.pid
end

$DEV = (ENV['RACK_ENV']=='development')
puts "run DEV: #{$DEV}"


root = ::File.dirname(__FILE__)

# speakintegtare
require ::File.join(root, 'src/speak_integrate')
$sIntegrate = SpeakIntegrate.new

# twitter_adapter
# not require if dev, to decrease api call
require ::File.join(root, 'src/adapt_twitter') if !$DEV

# server.rbをrequire
require ::File.join(root, 'server')

run Server
