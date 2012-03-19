require 'test_helper'

class Admin::SearchTabFiltersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:admin_search_tab_filters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create search_tab_filter" do
    assert_difference('Admin::SearchTabFilter.count') do
      post :create, :search_tab_filter => { }
    end

    assert_redirected_to search_tab_filter_path(assigns(:search_tab_filter))
  end

  test "should show search_tab_filter" do
    get :show, :id => admin_search_tab_filters(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => admin_search_tab_filters(:one).id
    assert_response :success
  end

  test "should update search_tab_filter" do
    put :update, :id => admin_search_tab_filters(:one).id, :search_tab_filter => { }
    assert_redirected_to search_tab_filter_path(assigns(:search_tab_filter))
  end

  test "should destroy search_tab_filter" do
    assert_difference('Admin::SearchTabFilter.count', -1) do
      delete :destroy, :id => admin_search_tab_filters(:one).id
    end

    assert_redirected_to admin_search_tab_filters_path
  end
end
