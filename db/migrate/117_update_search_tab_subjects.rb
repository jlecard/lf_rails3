


class UpdateSearchTabSubjects < ActiveRecord::Migration

  def self.up
    add_column(:search_tab_subjects, :collection_group_id, :integer)
  end
  
  def self.down
    remove_column :search_tab_subjects, :collection_group_id
  end
  
  
end