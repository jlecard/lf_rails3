require "spec_helper"

describe SearchTabFiltersController do
  describe "routing" do

    it "routes to #index" do
      get("/search_tab_filters").should route_to("search_tab_filters#index")
    end

    it "routes to #new" do
      get("/search_tab_filters/new").should route_to("search_tab_filters#new")
    end

    it "routes to #show" do
      get("/search_tab_filters/1").should route_to("search_tab_filters#show", :id => "1")
    end

    it "routes to #edit" do
      get("/search_tab_filters/1/edit").should route_to("search_tab_filters#edit", :id => "1")
    end

    it "routes to #create" do
      post("/search_tab_filters").should route_to("search_tab_filters#create")
    end

    it "routes to #update" do
      put("/search_tab_filters/1").should route_to("search_tab_filters#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/search_tab_filters/1").should route_to("search_tab_filters#destroy", :id => "1")
    end

  end
end
