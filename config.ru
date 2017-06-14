require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'])

# server.rbをrequire
root = ::File.dirname(__FILE__)
require ::File.join(root, 'server')

puts "run mode: #{ENV['RACK_ENV']}"

run Server
