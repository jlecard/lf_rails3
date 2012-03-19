class DeleteTables < ActiveRecord::Migration
  def self.up
    drop_table :log_collection_group_usages
    drop_table :log_collection_usages
    drop_table :log_interaction_usages
    drop_table :log_list_movement
    drop_table :log_mail_exports
    drop_table :log_prints
    drop_table :log_rebonce_modes
    drop_table :log_rebonce_usages
    drop_table :log_search_words
  end
  
  def self.down
    
    create_table :log_collection_group_usages do |t|
      t.string :idSets
      t.timestamps
      t.string :idFilter
    end
    
    create_table :log_collection_usages do |t|
      t.string :idSets
      t.string :host
      t.string :idFilters
      t.timestamps
    end
    
    create_table :log_interaction_usages do |t|
      t.string :idObject
      t.integer :object_type
      t.integer :interaction_type
      t.integer :movement
      t.string :host
      t.string :uuid, :default => nil
      t.timestamps
    end
    
    create_table :log_list_movement do |t|
      t.string :idlist
      t.string :movement_type
      t.string :host
      t.string :uuid
      t.timestamps
    end
    
    create_table :log_mail_exports do |t|
      t.string :host
      t.string :idDoc
      t.string :document_type
      t.string :object_type
      t.timestamps
    end
    
    create_table :log_prints do |t|
      t.string :host
      t.string :idDoc
      t.string :document_type
      t.string :object_type
      t.timestamps
    end
    
    create_table :log_rebonce_modes do |t|
      t.string :mode
      t.string :host
      t.timestamps
    end
    
    create_table :log_rebonce_usages do |t|
      t.string :query
      t.string :filter
      t.string :host
      t.timestamps
    end
    
    create_table :log_search_words do |t|
      t.string :word
      t.string :request
      t.integer :nb_consult
      t.timestamps
    end
  end
end