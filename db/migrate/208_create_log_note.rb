class CreateLogNote < ActiveRecord::Migration
  def self.up
    create_table :log_notes do |t|
      t.string :host
      t.string :object_uid
      t.string :object_type
      t.string :note
      t.timestamps
    end
  end

  def self.down
    drop_table :log_notes
  end
end