require 'test_helper'

class SearchTabSubjectsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:search_tab_subjects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create search_tab_subject" do
    assert_difference('SearchTabSubject.count') do
      post :create, :search_tab_subject => { }
    end

    assert_redirected_to search_tab_subject_path(assigns(:search_tab_subject))
  end

  test "should show search_tab_subject" do
    get :show, :id => search_tab_subjects(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => search_tab_subjects(:one).id
    assert_response :success
  end

  test "should update search_tab_subject" do
    put :update, :id => search_tab_subjects(:one).id, :search_tab_subject => { }
    assert_redirected_to search_tab_subject_path(assigns(:search_tab_subject))
  end

  test "should destroy search_tab_subject" do
    assert_difference('SearchTabSubject.count', -1) do
      delete :destroy, :id => search_tab_subjects(:one).id
    end

    assert_redirected_to search_tab_subjects_path
  end
end
