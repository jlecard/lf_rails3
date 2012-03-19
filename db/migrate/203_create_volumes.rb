class CreateVolumes < ActiveRecord::Migration
  def self.up
    create_table :volumes do |t|
      t.column :call_num, :string
      t.column :collection_id, :int, :null => false
      t.column :dc_identifier, :string, :null => false
      t.column :number, :int
      t.column :availability, :string
      t.column :location, :string
      t.column :label, :string
      t.column :link_label, :string
      t.column :launch_url, :string
      t.column :link, :string
      t.column :support, :string
    end
    
    add_index :volumes, [:dc_identifier, :collection_id]
    add_index :volumes, :dc_identifier
    add_index :volumes, :collection_id
    add_index :volumes, :call_num
  end
  
  
  
  def self.down
    remove_index :volumes, :call_num
    remove_index :volumes, [:dc_identifier, :collection_id]
    drop_table :volumes
  end
end