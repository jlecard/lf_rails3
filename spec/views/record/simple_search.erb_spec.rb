require 'spec_helper'

describe "record/simple_search" do 
  
  it "renders the search box partial" do
    setup_search
    
    render :partial=>'/record/simple_search', locals=>{:filter_tab=>@filter_tab,:linkMenu=>@linkMenu,:groups_tab=>@groups_tab}
    
    
    rendered.should have_selector('form',
                                  :id=>'search_form',
                                  :method=>'post',
                                  :action=>'/record/search')
    rendered.should_not have_selector('div', :id =>"form_3")
    rendered.should contain("TEST_COLLECTION_GROUP")
    rendered.should contain("filter_label")
    
  end
end
