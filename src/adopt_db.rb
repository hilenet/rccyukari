
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'hoge.db'
)

# all log
# ip, text, times
class Log < ActiveRecord::Base
end

# banned ips table
# ip, times
class BannedIp < ActiveRecord::Base
end

