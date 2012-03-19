class CreateLogFacetteUsages < ActiveRecord::Migration
  def self.up
    create_table :log_facette_usages do |t|
      t.string :types
      t.timestamps
    end
  end

  def self.down
    drop_table :log_facette_usages
  end
end
