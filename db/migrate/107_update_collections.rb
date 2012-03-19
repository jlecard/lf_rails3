class UpdateCollections < ActiveRecord::Migration

  def self.up
    add_column(:collections, :filter_query, :text)
  end
  
  def self.down
    remove_column :collections, :filter_query
  end
  
  
end