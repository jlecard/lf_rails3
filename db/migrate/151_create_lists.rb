class CreateLists < ActiveRecord::Migration
  def self.up
    create_table :lists do |t|
      t.column :state, :integer
      t.column :title, :string, :limit => 255
      t.column :ptitle, :text
      t.column :description, :text
      t.column :updated_at, :timestamp
      t.column :created_at, :timestamp
      t.column :uuid, :string
      t.column :date_public, :timestamp
      t.column :date_end_public, :timestamp
      t.column :notes_count,          :integer,  :default => 0
      t.column :notes_avg,            :float,    :default => 0.0
      t.column :comments_count,       :integer,  :default => 0
      
    end
    add_index :lists, :uuid
    
  end
  
  def self.down
    drop_table :lists
  end
  
end
