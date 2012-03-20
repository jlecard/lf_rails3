require 'spec_helper'

describe "admin_search_tab_filters/new" do
  before(:each) do
    assign(:search_tab_filter, stub_model(Admin::SearchTabFilter).as_new_record)
  end

  it "renders new search_tab_filter form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => admin_search_tab_filters_path, :method => "post" do
    end
  end
end
