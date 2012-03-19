class CreateLogListMovement < ActiveRecord::Migration
  def self.up
    create_table :log_list_movement do |t|
      t.string :idlist
      t.string :movement_type
      t.string :host
      t.string :uuid
      t.timestamps
    end
  end

  def self.down
    drop_table :log_list_movement
  end
end
