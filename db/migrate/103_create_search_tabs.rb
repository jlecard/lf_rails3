class CreateSearchTabs < ActiveRecord::Migration
  def self.up
    create_table :search_tabs do |t|
      t.string :label
      t.string :description
    end
    tab = SearchTab.create(:label => "Tout", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "Livres", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "Revues et articles", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "Musique", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "Films", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "Autoformation", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "Sites et bases de donn&eacute;es", :description => "")
    tab.save!
  end

  def self.down
    drop_table :search_tabs
  end
end
