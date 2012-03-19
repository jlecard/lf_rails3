


class UpdateCollectionGroupMembers < ActiveRecord::Migration

  def self.up
    add_column(:collection_group_members, :filter_query, :text)
  end
  
  def self.down
    remove_column :collection_group_members, :filter_query
  end
  
  
end