class UpdateDocumentTypesAddCollectionId < ActiveRecord::Migration
  
  def self.up
    remove_column :document_types, :document_type
    add_column :document_types, :collection_id, :integer
    add_column :document_types, :primary_document_type, :integer, :default => 1
  end

  def self.down
    add_column :document_types, :document_type, :string
    remove_column :document_types, :collection_id
    remove_column :document_types, :primary_document_type
  end
  
end