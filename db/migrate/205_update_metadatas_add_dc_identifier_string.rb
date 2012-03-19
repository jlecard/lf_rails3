class UpdateMetadatasAddDcIdentifierString < ActiveRecord::Migration
  
  def self.up
    add_column :metadatas, :dc_identifier_string, :string
    execute "UPDATE metadatas set dc_identifier_string = dc_identifier;"
    rename_column :metadatas, :dc_identifier, :dc_identifier_text
    rename_column :metadatas, :dc_identifier_string, :dc_identifier
    add_index :metadatas, :dc_identifier
  end
  
  
  
  def self.down
    remove_index :metadatas, :dc_identifier
    remove_column :dc_identifier
  end
end