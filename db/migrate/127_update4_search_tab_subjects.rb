
class Update4SearchTabSubjects < ActiveRecord::Migration

  def self.up
    add_column(:search_tab_subjects, :hide, :boolean, :default => 0)
  end
  
  def self.down
    remove_column (:search_tab_subjects, :hide)
  end

end
