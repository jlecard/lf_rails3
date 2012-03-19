class CreateHistorySearches < ActiveRecord::Migration
  def self.up
    create_table :history_searches do |t|
          t.column :search_input,     :string,    :null => false
          t.column :search_group,     :string,    :null => false
          t.column :search_type,      :string,    :null => false
          t.column :tab_filter,       :string,  :null => false
          t.column :search_operator1, :string
          t.column :search_input2,    :string
          t.column :search_type2,     :string
          t.column :search_operator2, :string
          t.column :search_input3,    :string
          t.column :search_type3,     :string
    end
  end

  def self.down
    drop_table :history_searches
  end
end
