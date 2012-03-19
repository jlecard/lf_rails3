class Update2SearchTabSubjects < ActiveRecord::Migration

  def self.up
    add_column(:search_tab_subjects, :description, :string)
  end
  
  def self.down
    remove_column (:search_tab_subjects, :description)
  end

end