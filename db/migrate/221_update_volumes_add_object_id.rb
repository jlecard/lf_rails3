class UpdateVolumesAddObjectId < ActiveRecord::Migration
  
  def self.up
    add_column :volumes, :object_id, :int
    add_column :volumes, :document_id, :int
    add_column :volumes, :barcode, :int
    add_column :volumes, :source, :string
  end
  
  
  
  def self.down
    remove_column :volumes, :object_id
    remove_column :volumes, :document_id
    remove_column :volumes, :barcode
    remove_column :volumes, :source
  end
end