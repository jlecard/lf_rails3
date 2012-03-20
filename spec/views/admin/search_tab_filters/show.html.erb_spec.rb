require 'spec_helper'

describe "admin_search_tab_filters/show" do
  before(:each) do
    @search_tab_filter = assign(:search_tab_filter, stub_model(Admin::SearchTabFilter))
  end

  it "renders attributes in <p>" do
    render
  end
end
