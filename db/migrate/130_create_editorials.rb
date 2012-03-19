class CreateEditorials < ActiveRecord::Migration
  def self.up
    create_table :editorials do |t|
      t.column :label, :string
      t.column :html, :text
      t.column :activate, :boolean, :default => true
    end
    
    create_table :editorial_group_members do |t|
      t.column :collection_group_id,  :integer
      t.column :editorial_id, :integer
      t.column :rank, :integer, :default => 0
    end
    
    add_index :editorial_group_members, :collection_group_id
    add_index :editorial_group_members, :editorial_id
  end

  def self.down
    drop_table :editorial_group_members
    drop_table :editorials
  end
end
