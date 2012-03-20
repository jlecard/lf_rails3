require 'spec_helper'

describe "search_tab_filters/index" do
  before(:each) do
    assign(:search_tab_filters, [
      stub_model(SearchTabFilter),
      stub_model(SearchTabFilter)
    ])
  end

  it "renders a list of search_tab_filters" do
    render
  end
end
