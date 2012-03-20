require 'spec_helper'


describe SearchTabFilter do
  it "should load the filters corresponding" do
    tab_id = factory_tabs
    filters = SearchTabFilter.load_filter(tab_id)
    filters.should be_a(Array)
    filters.should_not be_empty
    filters[0].should be_a(SearchTabFilter)
    filters[0].field_filter.should == "title"
  end
end
