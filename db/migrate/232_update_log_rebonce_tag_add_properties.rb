class UpdateLogRebonceTagAddProperties < ActiveRecord::Migration
  def self.up
    
    remove_column :log_rebonce_tags, :mode
    remove_column :log_rebonce_tags, :id_mode
    remove_column :log_rebonce_tags, :word
    remove_column :log_rebonce_tags, :uuid
    
    add_column :log_rebonce_tags, :object_type, :integer
    add_column :log_rebonce_tags, :object_uid, :string
    add_column :log_rebonce_tags, :profil, :string
    add_column :log_rebonce_tags, :tag_id, :integer
    
  end
  
  def self.down
    
    remove_column :log_rebonce_tags, :object_type
    remove_column :log_rebonce_tags, :object_uid
    remove_column :log_rebonce_tags, :profil
    remove_column :log_rebonce_tags, :tag_id
    
    add_column :log_rebonce_tags, :mode, :string
    add_column :log_rebonce_tags, :id_mode, :string
    add_column :log_rebonce_tags, :word, :string
    add_column :log_rebonce_tags, :uuid, :string
  end
end