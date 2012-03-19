class UpdateHistorySearchesAddTheme < ActiveRecord::Migration
  def self.up
    add_column :history_searches, :search_tab_subject_id, :integer, :default => -1
  end
  
  def self.down
    remove_column :history_searches, :search_tab_subject_id
  end
end