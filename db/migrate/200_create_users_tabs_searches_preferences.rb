class CreateUsersTabsSearchesPreferences < ActiveRecord::Migration
  def self.up
    create_table :users_tabs_searches_preferences do |t|
      t.column :uuid,         :string,      :null => false
      t.column :search_tab,   :integer,     :default => DEFAULT_SEARCH_TAB      
      t.column :search_group, :string,      :default => DEFAULT_SEARCH_GROUP
      t.column :search_type,  :string,     :default => DEFAULT_SEARCH_TYPE
    end
  end
  
  def self.down
    drop_table :users_tabs_searches_preferences
  end
end