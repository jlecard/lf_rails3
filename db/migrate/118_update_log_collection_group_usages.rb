


class UpdateLogCollectionGroupUsages < ActiveRecord::Migration

  def self.up
    add_column(:log_collection_group_usages, :idFilter, :string)
  end
  
  def self.down
    remove_column(:log_collection_group_usages, :idFilter)
  end
  
end