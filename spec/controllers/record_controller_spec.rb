require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe RecordController do

  # This should return the minimal set of attributes required to create a valid
  # Record. As you add validations to Record, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end
  
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # RecordsController. Be sure to keep this updated too.
  def valid_session
    {}
  end
  
  describe "GET search with no params" do
    it "should render a default search page" do
      get :search, {}, valid_session
      assigns[:client_ip].should == request.env["HTTP_CLIENT_IP"]
      assigns[:client_host].should == request.env["HOST"]
      assigns[:client_url].should == request.url
      assigns[:theme].should be_a(SearchTabSubject)
      assigns[:filter_tab].should be_a Array
      assigns[:filter_tab].should == []
      assigns[:page_size].should == 10
      assigns[:tab_query_string].should be_a Array
      assigns[:operator].should be_a Array
      assigns[:idTab].should == 1
      assigns[:type][0].should == "keyword"
      link_menu = assigns[:linkMenu] 
      link_menu.size.should == 7
      link_menu[0].should be_a(SearchTab)
      link_menu[0].label.should == "ALL"
      assigns[:groups_tab].should == []
      
      op = assigns[:operator]
      op[0].should == "AND"
      op[1].should == "AND"
      response.should render_template("accueil_all")
    end
    
  end
  
  describe "GET search with params" do
    it "call with tab param, should render a search page on current tab" do
      get :search, {:idTab=>3}, valid_session
      assigns[:idTab].should == 3.to_s
      response.should render_template("accueil_all")
    end
    
    it "call with query, type, group param, set, should render 
              a search page and assign varialbes" do
      get :search, {:idTab=>3,:query=>"String to search",:type=>"keyword",:sets=>"g3"}, 
                    valid_session
                    
      assigns[:idTab].should == 3.to_s
      tab_query = assigns[:tab_query_string] 
      tab_query.size.should == 1
      tab_query[0].should == "String to search"
      filter = assigns[:field_filter] 
      filter.should be_a(Array)
      filter.size.should == 1
      filter[0].should == "keyword"
      assigns[:sets].should == "g3"
      response.should render_template("accueil_all")
    end
    
  end

  describe "GET retrieve with no parameters at all" do
    it "should render back to accueil page with notice" do
      get :retrieve, {}, valid_session
      flash[:notice].should == "No query"
      response.should render_template("accueil_all")
    end
  end
  
  describe "GET retrieve with query parameters " do
    it "when only query parameter set, should set default search values
        and render the accueil template page because no group in db" do
      get :retrieve, {:query=>"test"}, valid_session
      assigns[:sets].should == ""
      assigns[:idTab].should == 1
      assigns[:type][0].should == "keyword"
      flash[:notice].should == "No collection group selected"
      response.should render_template("accueil_all")
    end
    
    it "when only query parameter set, should set default search values
        and render the intermediate template page, one collection group is 
        created but with no assiociated collections" do
      cg = Factory(:collection_group)  
      get :retrieve, {:query=>"test"}, valid_session
      assigns[:sets].should == "g#{cg.id}"
      assigns[:idTab].should == 1
      assigns[:type][0].should == "keyword"
      assigns[:jobs].should be_a(Array)
      assigns[:jobs].size.should == 0
      response.should render_template("intermediate")
    end
    
  end

  

end