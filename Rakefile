require 'yaml'
require 'active_record'

# db周り
namespace :db do
  desc "load config file"
  task :configuration do
    @db_config = YAML.load_file 'config/database.yml'
  end

  desc "connect do db"
  task :connection => :configuration do
    ActiveRecord::Base.establish_connection @db_config['db']
  end

  desc "migrate db"
  task :migrate => :connection do
    ActiveRecord::Migrator.migrate 'db/migrate'
  end

  desc "delete db"
  task :drop => :connection do
    #ActiveRecord::Base.connection.drop_database @db_config['db']
    ActiveRecord::Migrator.down 'db/migrate'
  end
end
