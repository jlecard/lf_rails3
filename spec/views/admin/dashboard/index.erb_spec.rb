require 'spec_helper'


describe "/admin/dashboard/index" do
  it "shows index page with links to main items" do
    render :template => '/admin/dashboard/index',:layout => 'layouts/admin'

    rendered.should have_selector('div',:id=>"sub-container")
    rendered.should have_selector("div",:class=>"xboxcontent left") 

    rendered.should have_selector("h2", :id=>"browsetitle")
    rendered.should contain("Administration")

    rendered.should have_selector("div", :id=>"t_nav") do |nav|
      nav.should have_selector("span", :count=>14)
    end
    
    rendered.should have_selector('div', :id=>'admin-box')
    
    rendered.should have_selector('a', :href=>'/admin/collection/list') do |box|
      box.should have_selector('div', :class=>'collections-box')
    end
    rendered.should have_selector('a', :href=>'/admin/collection_group/list')do |box|
      box.should have_selector('div', :class=>'collection-groups-box')  
    end
     
    rendered.should have_selector('a', :href=>'user/list') do |box| 
      box.should have_selector('div', :class=>'users-box')
    end
  end
end 