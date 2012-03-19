class CreateHarvestSchedule < ActiveRecord::Migration
  def self.up
    create_table :harvest_schedules, :force =>true do |t|
      t.column :time, :time, :null => false
      t.column :collection_id, :int, :default => 0
    end
    execute('ALTER TABLE harvest_schedules add day ENUM("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday") NOT NULL;')
    add_index :harvest_schedules, :collection_id
    add_index :harvest_schedules, [:collection_id, :day, :time], :unique=>true
  end

  def self.down
    remove_index :harvest_schedules, :collection_id
    remove_index :harvest_schedules, [:collection_id, :day, :time]
    drop_table :harvest_schedules
  end
end