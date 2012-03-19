class UpdateCollectionAddOaiset < ActiveRecord::Migration
  def self.up
    add_column :collections, :oai_set, :string, :default => nil
  end

  def self.down
    remove_column :collections, :oai_set
  end
end