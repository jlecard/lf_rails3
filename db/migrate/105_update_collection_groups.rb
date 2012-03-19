class UpdateCollectionGroups < ActiveRecord::Migration

  def self.up
    add_column(:collection_groups, :display_advanced_search, :boolean, :default => false)
    add_column(:collection_groups, :tab_id, :integer, :default => 0)
  end
  
  def self.down
    remove_column :collection_groups, :display_advanced_search
    remove_column :collection_groups, :tab_id
  end
  
  
end