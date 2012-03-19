
class Update5SearchTabSubjects < ActiveRecord::Migration

  def self.up
    add_column(:search_tab_subjects, :format, :string, :default => 'request')
    add_column(:search_tab_subjects, :url, :string, :default => '')
  end
  
  def self.down
    remove_column (:search_tab_subjects, :format)
    remove_column (:search_tab_subjects, :url)
  end

end
