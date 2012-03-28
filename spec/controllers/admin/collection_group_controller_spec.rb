#encoding: utf-8
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
require 'rails3-jquery-autocomplete'

describe Admin::CollectionGroupController do
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

  describe "UNAUTHENTICATED GET list with no params" do
    it "should redirect to login page" do
      get :list, {}, valid_session
      response.should redirect_to('/user/login?locale=fr')

    end

  end

  without_transactional_fixtures do
    describe "AUTHENTICATE GET list" do
      before(:each) do
        authenticate_admin
      end
      describe "no params" do
        it "should assign default page for collections" do
          get :list, {}, session.to_hash
          response.should_not redirect_to('/user/login?locale=fr')
          assigns[:display_columns].should == ['full_name', 'name']
          params = assigns[:params]
          params.should be_nil
          assigns[:page].should == "1"
          assigns[:pages].size.should == 0
        end
      end
      describe "no data, list page 2" do
        it "should assign default page for collections" do
          get 'list', {:page=>2}, session.to_hash
          response.should_not redirect_to('/user/login?locale=fr')
          assigns[:display_columns].should == ['full_name', 'name']
          assigns[:page].should == "2"
          assigns[:pages].size.should == 0
        end
      end
      describe "add collection_groups, access page 2" do
        it "should show page 2" do
          25.times do
            Factory(:collection_group_seq)
          end
          get :list, {:page=>2}, session.to_hash
          assigns[:page].should == "2"
          pages = assigns(:pages)
          pages.previous_page.should == 1
          pages.offset.should == 20
          pages.total_entries.should == 25
          pages.total_pages.should == 2
        end
      end

    end
    describe "AUTHENTICATE GET create" do
      before(:each) do
        authenticate_admin
      end
      it "creates a new collection group" do
        expect {
          post :create, {:collection_group => Factory.attributes_for(:collection_group)}, session.to_hash
        }.to change(CollectionGroup, :count).by(1)
        assigns(:collection_group).should be_a(CollectionGroup)
        assigns(:collection_group).should be_persisted
        flash[:notice].should == I18n.translate("COLLECTION_GROUP_CREATED")
        response.should redirect_to(list_admin_collection_group_index_path)
      end
      it "redirects to new collection group page" do
        expect {
          post :create, {:collection_group => Factory.attributes_for(:collection_group,:name=>'')}, session.to_hash
        }.to change(CollectionGroup, :count).by(0)
        response.should render_template("new")
        assigns(:collection_group).errors.size.should == 1
        assigns(:collection_group).errors.full_messages[0].should match(/Name/)
      end
    end
  end

end
