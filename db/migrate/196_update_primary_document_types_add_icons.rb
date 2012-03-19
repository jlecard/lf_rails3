class UpdatePrimaryDocumentTypesAddIcons < ActiveRecord::Migration
  
  def self.up
    add_column :primary_document_types, :display_icon, :string, :default => "unknown"
    add_column :primary_document_types, :no_image_icon, :string, :default => "unknown"
  end
  
  def self.down
    remove_column :primary_document_types, :display_icon
    remove_column :primary_document_types, :no_image_icon
  end
  
end