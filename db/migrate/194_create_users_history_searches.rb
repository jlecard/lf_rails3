class CreateUsersHistorySearches < ActiveRecord::Migration
  def self.up
    create_table :users_history_searches do |t|
      t.column :uuid,             :string,    :null => false
      t.column :save_date,        :datetime
      t.column :results_count,    :integer,   :default => 0
      t.column :id_history_search, :integer, :null => false
    end
  end
  
  def self.down
    drop_table :users_history_searches
  end
end