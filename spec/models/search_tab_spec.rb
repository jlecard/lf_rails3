require 'spec_helper'

describe SearchTab do
  it "should create a new SearchTab" do
    search_tab = SearchTab.new
    search_tab.should be_a(SearchTab)
    search_tab.label = "test"
    search_tab.save
    search_tab.label.should == "test"
  end
  
  it "should load all tabs" do 
    factory_tabs
    menu = SearchTab.load_menu
    expected = SearchTab.find(:all)
    menu.should eq(expected)
  end
  
  it "should load groups" do 
    id = factory_tabs
    Factory(:search_collection_group, :tab_id=>id)
    groups = SearchTab.load_groups(id)
    groups.should be_a(Array)
    groups.count.should == 1
    groups[0].name.should == "TEST_COLLECTION_GROUP"
  end
end
