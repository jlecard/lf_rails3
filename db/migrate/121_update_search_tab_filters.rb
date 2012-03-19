class UpdateSearchTabFilters < ActiveRecord::Migration

  def self.up
    add_column(:search_tab_filters, :description, :string)
  end
  
  def self.down
    remove_column(:search_tab_filters, :description)
  end
  
end