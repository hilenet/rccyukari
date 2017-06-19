require 'yaml'
require 'sqlite3'
require 'active_record'

config = YAML.load_file 'config/database.yml'
ActiveRecord::Base.establish_connection config['db']

# all log
# ip, text, times
class Log < ActiveRecord::Base
end

# banned ips table
# ip, times
class BannedIp < ActiveRecord::Base
end

