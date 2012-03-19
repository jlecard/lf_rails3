class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.datetime :note_date
      t.string :uuid
      t.integer :note
      t.integer :object
      t.string :object_id
    end
  end

  def self.down
    drop_table :notes
  end
end