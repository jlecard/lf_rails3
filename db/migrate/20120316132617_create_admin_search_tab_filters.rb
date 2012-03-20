class CreateAdminSearchTabFilters < ActiveRecord::Migration
  def change
    create_table :admin_search_tab_filters do |t|

      t.timestamps
    end
  end
end
