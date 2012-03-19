class UpdateCollectionTabsHarvestingDay < ActiveRecord::Migration
  def self.up
    add_column :collections, :harvest_day, :string, :default => "0123456"
  end
  
  def self.down
    remove_column :collections, :harvest_day
  end
end
