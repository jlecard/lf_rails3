class UpdateCollectionsAddActionsAllowed < ActiveRecord::Migration
  def self.up
    add_column :collections, :actions_allowed, :boolean, :default => false
  end
  
  def self.down
    remove_column :collections, :actions_allowed
  end
end