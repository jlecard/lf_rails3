class UpdateLogSearchAddProperties < ActiveRecord::Migration
  def self.up
    
    add_column :log_searches, :profil, :string
    add_column :log_searches, :context, :string
    add_column :log_searches, :search_tab_subject_id, :int, :default => nil
    add_index :log_searches, :context
  end
  
  def self.down
    remove_column :log_searches, :profil
    remove_column :log_searches, :search_tab_subject_id
    remove_index :log_searches, :context
    remove_column :log_searches, :context
  end
end