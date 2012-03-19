class CreateLogCollectionUsages < ActiveRecord::Migration
  def self.up
    create_table :log_collection_usages do |t|
      t.string :idSets
      t.string :host
      t.string :idFilters
      t.timestamps
    end
  end

  def self.down
    drop_table :log_collection_usages
  end
end