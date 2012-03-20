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

describe SearchTabFiltersController do

  # This should return the minimal set of attributes required to create a valid
  # SearchTabFilter. As you add validations to SearchTabFilter, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end
  
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SearchTabFiltersController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all search_tab_filters as @search_tab_filters" do
      search_tab_filter = SearchTabFilter.create! valid_attributes
      get :index, {}, valid_session
      assigns(:search_tab_filters).should eq([search_tab_filter])
    end
  end

  describe "GET show" do
    it "assigns the requested search_tab_filter as @search_tab_filter" do
      search_tab_filter = SearchTabFilter.create! valid_attributes
      get :show, {:id => search_tab_filter.to_param}, valid_session
      assigns(:search_tab_filter).should eq(search_tab_filter)
    end
  end

  describe "GET new" do
    it "assigns a new search_tab_filter as @search_tab_filter" do
      get :new, {}, valid_session
      assigns(:search_tab_filter).should be_a_new(SearchTabFilter)
    end
  end

  describe "GET edit" do
    it "assigns the requested search_tab_filter as @search_tab_filter" do
      search_tab_filter = SearchTabFilter.create! valid_attributes
      get :edit, {:id => search_tab_filter.to_param}, valid_session
      assigns(:search_tab_filter).should eq(search_tab_filter)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new SearchTabFilter" do
        expect {
          post :create, {:search_tab_filter => valid_attributes}, valid_session
        }.to change(SearchTabFilter, :count).by(1)
      end

      it "assigns a newly created search_tab_filter as @search_tab_filter" do
        post :create, {:search_tab_filter => valid_attributes}, valid_session
        assigns(:search_tab_filter).should be_a(SearchTabFilter)
        assigns(:search_tab_filter).should be_persisted
      end

      it "redirects to the created search_tab_filter" do
        post :create, {:search_tab_filter => valid_attributes}, valid_session
        response.should redirect_to(SearchTabFilter.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved search_tab_filter as @search_tab_filter" do
        # Trigger the behavior that occurs when invalid params are submitted
        SearchTabFilter.any_instance.stub(:save).and_return(false)
        post :create, {:search_tab_filter => {}}, valid_session
        assigns(:search_tab_filter).should be_a_new(SearchTabFilter)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        SearchTabFilter.any_instance.stub(:save).and_return(false)
        post :create, {:search_tab_filter => {}}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested search_tab_filter" do
        search_tab_filter = SearchTabFilter.create! valid_attributes
        # Assuming there are no other search_tab_filters in the database, this
        # specifies that the SearchTabFilter created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        SearchTabFilter.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => search_tab_filter.to_param, :search_tab_filter => {'these' => 'params'}}, valid_session
      end

      it "assigns the requested search_tab_filter as @search_tab_filter" do
        search_tab_filter = SearchTabFilter.create! valid_attributes
        put :update, {:id => search_tab_filter.to_param, :search_tab_filter => valid_attributes}, valid_session
        assigns(:search_tab_filter).should eq(search_tab_filter)
      end

      it "redirects to the search_tab_filter" do
        search_tab_filter = SearchTabFilter.create! valid_attributes
        put :update, {:id => search_tab_filter.to_param, :search_tab_filter => valid_attributes}, valid_session
        response.should redirect_to(search_tab_filter)
      end
    end

    describe "with invalid params" do
      it "assigns the search_tab_filter as @search_tab_filter" do
        search_tab_filter = SearchTabFilter.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        SearchTabFilter.any_instance.stub(:save).and_return(false)
        put :update, {:id => search_tab_filter.to_param, :search_tab_filter => {}}, valid_session
        assigns(:search_tab_filter).should eq(search_tab_filter)
      end

      it "re-renders the 'edit' template" do
        search_tab_filter = SearchTabFilter.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        SearchTabFilter.any_instance.stub(:save).and_return(false)
        put :update, {:id => search_tab_filter.to_param, :search_tab_filter => {}}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested search_tab_filter" do
      search_tab_filter = SearchTabFilter.create! valid_attributes
      expect {
        delete :destroy, {:id => search_tab_filter.to_param}, valid_session
      }.to change(SearchTabFilter, :count).by(-1)
    end

    it "redirects to the search_tab_filters list" do
      search_tab_filter = SearchTabFilter.create! valid_attributes
      delete :destroy, {:id => search_tab_filter.to_param}, valid_session
      response.should redirect_to(search_tab_filters_url)
    end
  end

end