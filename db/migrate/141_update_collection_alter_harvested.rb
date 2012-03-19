class UpdateCollectionAlterHarvested < ActiveRecord::Migration
  def self.up
    change_column :collections, :harvested, :datetime, :default => nil
  end

  def self.down
    change_column :collections, :harvested, :string, :default => nil
  end
end