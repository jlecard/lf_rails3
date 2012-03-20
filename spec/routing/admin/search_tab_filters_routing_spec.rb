require "spec_helper"

describe Admin::SearchTabFiltersController do
  describe "routing" do

    it "routes to #index" do
      get("/admin_search_tab_filters").should route_to("admin_search_tab_filters#index")
    end

    it "routes to #new" do
      get("/admin_search_tab_filters/new").should route_to("admin_search_tab_filters#new")
    end

    it "routes to #show" do
      get("/admin_search_tab_filters/1").should route_to("admin_search_tab_filters#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin_search_tab_filters/1/edit").should route_to("admin_search_tab_filters#edit", :id => "1")
    end

    it "routes to #create" do
      post("/admin_search_tab_filters").should route_to("admin_search_tab_filters#create")
    end

    it "routes to #update" do
      put("/admin_search_tab_filters/1").should route_to("admin_search_tab_filters#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin_search_tab_filters/1").should route_to("admin_search_tab_filters#destroy", :id => "1")
    end

  end
end
