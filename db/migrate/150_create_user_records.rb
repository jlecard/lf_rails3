class CreateUserRecords < ActiveRecord::Migration
  def self.up
    create_table :user_records, :primary_key => [:doc_identifier, :doc_collection_id, :uuid]  do |t|
      t.column :doc_identifier,      :string,      :null => false,  :limit => 255
      t.column :doc_collection_id,   :integer,     :null => false
      t.column :uuid,                :string,      :null => false
      t.column :date_insert,         :timestamp
    end
  end
  
  def self.down
    drop_table :user_records
  end
  
end
