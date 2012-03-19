require 'test_helper'

class PrimaryDocumentTypesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:primary_document_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create primary_document_type" do
    assert_difference('PrimaryDocumentType.count') do
      post :create, :primary_document_type => { }
    end

    assert_redirected_to primary_document_type_path(assigns(:primary_document_type))
  end

  test "should show primary_document_type" do
    get :show, :id => primary_document_types(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => primary_document_types(:one).id
    assert_response :success
  end

  test "should update primary_document_type" do
    put :update, :id => primary_document_types(:one).id, :primary_document_type => { }
    assert_redirected_to primary_document_type_path(assigns(:primary_document_type))
  end

  test "should destroy primary_document_type" do
    assert_difference('PrimaryDocumentType.count', -1) do
      delete :destroy, :id => primary_document_types(:one).id
    end

    assert_redirected_to primary_document_types_path
  end
end
