class UpdateVolumesAddMetadataId < ActiveRecord::Migration
  
  def self.up
    add_column :volumes, :metadata_id, :int
    execute "UPDATE volumes V set metadata_id = (SELECT id from metadatas M where V.dc_identifier = M.dc_identifier AND V.collection_id = M.collection_id)"
    add_index :volumes, :metadata_id
  end
  
  
  
  def self.down
    remove_index :volumes, :metadata_id
    remove_column :metadata_id
  end
end