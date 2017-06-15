require 'sqlite3'
require 'active_record'

ActiveRecord::Base.establish_connection("adapter": "sqlite3", "database": "hoge.db")

### TimezoneがUST ###
ActiveRecord::Migration.create_table(:logs) do |t|
  t.string :ip
  t.string :text
  t.timestamps
end

ActiveRecord::Migration.create_table(:banned_ips) do |t|
  t.string :ip
  t.timestamps
end

