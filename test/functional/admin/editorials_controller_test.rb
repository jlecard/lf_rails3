require 'test_helper'

class Admin::EditorialsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:admin_editorials)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create editorial" do
    assert_difference('Admin::Editorial.count') do
      post :create, :editorial => { }
    end

    assert_redirected_to editorial_path(assigns(:editorial))
  end

  test "should show editorial" do
    get :show, :id => admin_editorials(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => admin_editorials(:one).id
    assert_response :success
  end

  test "should update editorial" do
    put :update, :id => admin_editorials(:one).id, :editorial => { }
    assert_redirected_to editorial_path(assigns(:editorial))
  end

  test "should destroy editorial" do
    assert_difference('Admin::Editorial.count', -1) do
      delete :destroy, :id => admin_editorials(:one).id
    end

    assert_redirected_to admin_editorials_path
  end
end
