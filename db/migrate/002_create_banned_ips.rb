class CreateBannedIps < ActiveRecord::Migration[5.0]
  def self.up
    create_table :banned_ips do |t|
      t.string :ip
      t.timestamps # TimezoneがUSTなので注意
    end
  end

  def self.down
    drop_table :banned_ips
  end
end
