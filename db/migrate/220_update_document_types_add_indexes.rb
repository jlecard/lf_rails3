class UpdateDocumentTypesAddIndexes < ActiveRecord::Migration
  
  def self.up
    add_index :document_types, :collection_id
    add_index :document_types, :primary_document_type
    add_index :document_types, [:collection_id, :primary_document_type]
    add_index :primary_document_types, :name
  end
  
  
  
  def self.down
    remove_index :document_types, :collection_id
    remove_index :document_types, :primary_document_type
    remove_index :document_types, [:collection_id, :primary_document_type]
    remove_index :primary_document_types, :name
  end
end