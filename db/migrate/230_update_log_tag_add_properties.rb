class UpdateLogTagAddProperties < ActiveRecord::Migration
  def self.up
    add_column :log_tags, :profil, :string
    add_column :log_tags, :object_uid, :string
    add_column :log_tags, :tag_id, :integer
    add_column :log_tags, :int_add, :integer
    add_column :log_tags, :tag_label, :string
    
    remove_column :log_tags, :uuid
    remove_column :log_tags, :tag
  end
  
  def self.down
    
    remove_column :log_tags, :profil
    remove_column :log_tags, :object_uid
    remove_column :log_tags, :tag_id
    remove_column :log_tags, :int_add
    remove_column :log_tags, :tag_label
    
    add_column :log_tags, :uuid
    add_column :log_tags, :tag
    
  end
end