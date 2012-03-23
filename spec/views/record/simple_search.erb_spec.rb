require 'spec_helper'

describe "record/simple_search" do 
  
  it "renders the search box partial" do
    setup_search
    @tab_query_string = ["test search"]
    @field_filter = ["keyword"]
    @operator = "AND"
    @advanced = false
    render :partial=>'/record/simple_search', 
                      :locals=>{:filter_tab=>@filter_tab,
                                :linkMenu=>@linkMenu,
                                :groups_tab=>@groups_tab,
                                :sets=>'g1',
                                :idTab=>1,
                                :tab_query_string=>@tab_query_string}
    
    
    rendered.should have_selector('form',
                                  :id=>'search_form',
                                  :method=>'post',
                                  :action=>'/record/retrieve')
    rendered.should_not have_selector('div', :id =>"form_3")
    
    rendered.should have_selector('div', :id=>'advanceForm')
    
    rendered.should contain("TEST_COLLECTION_GROUP")
    rendered.should contain("filter_label")
    
  end
end
