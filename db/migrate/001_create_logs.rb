class CreateLogs < ActiveRecord::Migration[5.0]
  def self.up
    create_table :logs do |t|
      t.string :ip
      t.string :text
      t.timestamps # TimezoneがUSTなので注意
    end
  end

  def self.down
    drop_table :logs
  end
end
