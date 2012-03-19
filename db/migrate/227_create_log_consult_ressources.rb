class CreateLogConsultRessources < ActiveRecord::Migration
  def self.up
    create_table :log_consult_ressources do |t|
      t.integer :collection_id
      t.string :host
      t.string :doc_identifier
      t.string :profil
      t.integer :indoor
      t.timestamps
    end
    
    add_index :log_consult_ressources, :collection_id
    add_index :log_consult_ressources, :indoor
  end
  
  def self.down
#    remove_index :log_consult_ressources, :collection_id
#    remove_index :log_consult_ressources, :indoor
    
    drop_table :log_consult_ressources
  end
end