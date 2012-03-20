require 'spec_helper'

describe "search_tab_filters/edit" do
  before(:each) do
    @search_tab_filter = assign(:search_tab_filter, stub_model(SearchTabFilter))
  end

  it "renders the edit search_tab_filter form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => search_tab_filters_path(@search_tab_filter), :method => "post" do
    end
  end
end
