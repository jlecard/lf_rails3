class UpdateMetadataAddDclanguage < ActiveRecord::Migration
  def self.up
    add_column(:metadatas, :dc_language, :string)
  end
  
  def self.down
    remove_column :metadatas, :dc_language
  end
end
