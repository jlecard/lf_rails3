class CreateNoticesCheck < ActiveRecord::Migration
  def self.up
    create_table :notices_checks do |t|
      t.integer :doc_collection_id, :null => false
      t.string :doc_identifier, :null => false
    end
  end

  def self.down
    drop_table :notices_checks
  end
end