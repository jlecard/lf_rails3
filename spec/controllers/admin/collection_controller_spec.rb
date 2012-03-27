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

describe Admin::CollectionController do

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
          assigns[:display_columns].should == ['alt_name', 'name']
          params = assigns[:params]
          params.should be_nil
          assigns[:page].should == "1"
          assigns[:collection_pages].size.should == 0
        end
      end

      describe "add 50 collection groups and check pagination" do

        it "should should show 20 collections on second page" do
          50.times do
            Factory(:collection_seq)
          end
          get :list, {:page=>2}, session.to_hash
          response.should_not redirect_to('/user/login?locale=fr')
          assigns[:display_columns].should == ['alt_name', 'name']
          params = assigns[:params]
          params.should be_nil
          assigns[:page].should == "2"
          assigns[:collection_pages].size.should == 20
          assigns[:collection_pages].total_pages.should == 3
          assigns[:collection_pages].previous_page.should == 1
          assigns[:collection_pages].next_page.should == 3
        end
      end
    end

    describe "autocomplete on connection_type field" do
      before(:each) do
        authenticate_admin
      end
      it "should return distinct values" do
        10.times do
          Factory(:collection_seq)
          Factory(:collection_seq, :conn_type=>"z3950")
          Factory(:collection_seq, :conn_type=>"connector")
        end
        expected = [].to_json
        get :autocomplete_collection_conn_type,{:term=>'oaip'}
        response.body.should == expected
        
        expected = [].to_json
        get :autocomplete_collection_conn_type,{:term=>'poai'}
        response.body.should == expected

        expected = [{:id=>'',
                    :label=>'oai',
                    :value=>'oai'}].to_json
        get :autocomplete_collection_conn_type,{:term=>'oa'}
        response.body.should == expected

        expected = [{:id=>'',
                    :label=>'z3950',
                    :value=>'z3950'}].to_json
        get :autocomplete_collection_conn_type,{:term=>'z395'}
        response.body.should == expected
        
        expected = [{:id=>'',
                    :label=>'connector',
                    :value=>'connector'}].to_json
        get :autocomplete_collection_conn_type,{:term=>'co'}
        response.body.should == expected
      end
    end
  end

end
