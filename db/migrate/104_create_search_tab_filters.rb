class CreateSearchTabFilters < ActiveRecord::Migration
  def self.up
    create_table :search_tab_filters do |t|
      t.string :label
      t.string :field_filter
      t.column :search_tab_id, :integer
    end
  end

  def self.down
    drop_table :search_tab_filters
  end
end
