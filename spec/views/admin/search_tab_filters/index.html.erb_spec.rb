require 'spec_helper'

describe "admin_search_tab_filters/index" do
  before(:each) do
    assign(:admin_search_tab_filters, [
      stub_model(Admin::SearchTabFilter),
      stub_model(Admin::SearchTabFilter)
    ])
  end

  it "renders a list of admin_search_tab_filters" do
    render
  end
end
