require 'spec_helper'

describe "search_tab_filters/show" do
  before(:each) do
    @search_tab_filter = assign(:search_tab_filter, stub_model(SearchTabFilter))
  end

  it "renders attributes in <p>" do
    render
  end
end
