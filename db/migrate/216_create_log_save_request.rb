class CreateLogSaveRequest < ActiveRecord::Migration
  def self.up
    create_table :log_save_requests do |t|
      t.integer :search_history_id
      t.string :host
      t.timestamps
    end
  end

  def self.down
    drop_table :log_save_requests
  end
end