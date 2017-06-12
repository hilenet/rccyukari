require_relative 'src/adopt_db.rb'
require_relative 'src/speak_task.rb'

=begin
Thread.start do

end
=end


class Server < Sinatra::Base
  set :sockets, []
  set :tasks, []

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  get '/' do

    erb :index
  end

end
