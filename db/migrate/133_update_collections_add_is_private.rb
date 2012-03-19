class UpdateCollectionsAddIsPrivate < ActiveRecord::Migration
  def self.up
    add_column :collections, :is_private, :boolean, :default => false
  end

  def self.down
    remove_column :collections, :is_private
  end
end