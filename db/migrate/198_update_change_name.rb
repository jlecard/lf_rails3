class UpdateChangeName < ActiveRecord::Migration
  
  def self.up
    rename_column :comments, :object_id, :object_uid
    rename_column :comments, :object, :object_type
    
    rename_column :objects_tags, :object_id, :object_uid
    rename_column :objects_tags, :object, :object_type
    
    rename_column :subscriptions, :object_id, :object_uid
    rename_column :subscriptions, :object, :object_type
    
    rename_column :objects_counts, :object_id, :object_uid
    rename_column :objects_counts, :object, :object_type
    
    rename_column :notes, :object_id, :object_uid
    rename_column :notes, :object, :object_type
  end
  
  def self.down
    
    rename_column :comments, :object_uid, :object_id
    rename_column :comments, :object_type, :object
    
    rename_column :objects_tags, :object_uid, :object_id
    rename_column :objects_tags, :object_type, :object
    
    rename_column :subscriptions, :object_uid, :object_id
    rename_column :subscriptions, :object_type, :object
    
    rename_column :objects_counts, :object_uid, :object_id
    rename_column :objects_counts, :object_type, :object
    
    rename_column :notes, :object_uid, :object_id
    rename_column :notes, :object_type, :object
    
  end
  
end