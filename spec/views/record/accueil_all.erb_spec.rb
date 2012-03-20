require 'spec_helper'

describe "record/accueil_all" do 
  it "renders the default page layout" do
    setup_search
    render :template=>'/record/accueil_all', :layout => 'layouts/libraryfind'
    rendered.should have_selector("div", :class=>'container')
    rendered.should have_selector("div", :class=>'header')
    rendered.should have_selector("div", :class=>'menu-niv2')
    rendered.should have_selector("div", :class=>'left')
    rendered.should have_selector("div", :id=>'sub-container') do |sub|
      sub.should have_selector('form',
                                  :method=>'post',
                                  :action=>'/record/retrieve',
                                 :count=>1)  
      sub.should !have_selector('div', :class =>'hideElement')  
    end
    
  end
end
