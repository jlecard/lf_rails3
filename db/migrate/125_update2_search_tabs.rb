class Update2SearchTabs < ActiveRecord::Migration
  def self.up
    
    execute "TRUNCATE TABLE search_tabs"
    
    tab = SearchTab.create(:label => "ALL", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "BOOK", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "ARTICLE", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "MUSIC", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "MOVIE", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "TRAINING", :description => "")
    tab.save!
    tab = SearchTab.create(:label => "SITE", :description => "")
    tab.save!
    
    
  end

  def self.down
    
  end
end
