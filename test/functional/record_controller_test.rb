# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

require File.dirname(__FILE__) + '/../test_helper'
require 'record_controller'
require 'record_helper'

# Re-raise errors caught by the controller.
class RecordController; def rescue_action(e) raise e end; end

class RecordControllerTest < Test::Unit::TestCase
  def setup
    @controller = RecordController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
  end

  # Test that the index action is redirected to search
  def test_index
    get :index
    assert_template 'record/search'
  end
  
  #Test that all defaults are properly set on a retrieve action
  def test_retrieve_with_defaults
    post :retrieve, :query=>{"string"=>"water"}
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_equal "g2,g3", assigns["sets"]
    assert_defaults
    assert(assigns(:subjects).length>0)
    assert_results
  end
  
  def test_retrieve_with_sets_override
    post :retrieve, :query=>{"string"=>"water"}, :sets=>'g1,g2,g3,g4'
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g1,g2,g3,g4")
    assert(assigns(:subjects).length>0)
    assert_results
  end
  
  
  def assert_results
    assert_not_nil assigns(:results)
    assert(assigns(:results).length>0)
    assert(assigns(:databases).length>0)
    assert(assigns(:authors).length>0)
    #todo - figure out how to assert results_page
    #assert_not_nil assigns(:results_page)
    #assert(assigns(:results_page).length>1)
  end 
  
   
    #Test that all defaults are properly set on a retrieve_books action
  def test_retrieve_books_with_defaults
    post :retrieve, :query=>{"string"=>"oregon"},:sets=>"g4"
    assert_template 'record/general'
    assert_equal ['oregon'], assigns["query"]
    assert_equal "g4", assigns["sets"]
    assert_defaults
    assert(assigns(:subjects).length>0)
    assert_results
  end
   
  def test_retrieve_images_with_defaults
    post :retrieve, :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>'images'
    assert_template 'record/images'
    assert_equal ['education'], assigns["query"]
    assert_global_values("g3", ["keyword"], "25", 'relevance', [], 'images')  
    assert_results
  end
    
  def test_title_search
    post :retrieve, :query=>{"string"=>"oregon", "max"=>"25", "type"=>"title"}
    assert_template 'record/general'
    assert_equal ['oregon'], assigns["query"]   
    assert_global_values("g2,g3", ["title"])
    assert(assigns(:subjects).length>0)
    assert(assigns(:subjects).length>0)
    assert_results
  end
  
  def test_subject_search
    post :retrieve,:query=>{"string"=>"mathematics", "max"=>"25", "type"=>"subject"}
    assert_template 'record/general'
    assert_equal ['mathematics'], assigns["query"]
    assert_global_values("g2,g3", ["subject"])
    assert_results
  end
  
  def test_author_search
    post :retrieve, :query=>{"string"=>"Hendricks", "max"=>"25", "type"=>"author"}
    assert_template 'record/general'
    assert_equal ['Hendricks'], assigns["query"]
    assert_global_values("g2,g3", ["author"])
    assert_results
 end
 #comment out this test until terry adds max to caching 
  def test_max_search
    post :retrieve, :query=>{"string"=>"water", "max"=>"100"}
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g2,g3", ["keyword"], "100")
    assert(assigns(:results).length>100)
    assert_results
  end
  
  def test_material_filter
    post :retrieve, :query=>{"string"=>"water"}
    post :retrieve_page, :query=>{"string"=>"water"}, :filter=>"material_type:Book"
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g2,g3", ["keyword"], "25", 'relevance',[["material_type","Book"]])
    assert_results
  end
  
  def test_db_filter
    post :retrieve, :query=>{"string"=>"water"}
    post :retrieve_page, :query=>{"string"=>"water"}, :filter=>"vendor_name:Oregon State University Library Catalog"
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g2,g3", ["keyword"], "25", 'relevance',[["vendor_name","Oregon State University Library Catalog"]])
    assert_results
  end
  
  def test_date_sort
    post :retrieve, :query=>{"string"=>"water"}
    post :retrieve_page, :query=>{"string"=>"water"}, :sort_value=>"dateup"
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g2,g3", ["keyword"], "25", 'dateup')
    assert(assigns(:subjects).length>0)
    assert_results
  end
  
  def test_date_sort_images
    post :retrieve, :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>"images"
    post :retrieve_page, :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>"images", :sort_value=>"datedown"
    assert_global_values("g3", ["keyword"], "25", 'datedown', [], 'images')
    assert_template 'record/images'
    assert_equal ['education'], assigns["query"]
    assert_results
  end

  
  def test_date_sort_books
    post :retrieve, :query=>{"string"=>"water"}, :sets=>"g4"
    post :retrieve_page, :query=>{"string"=>"water"}, :sets=>"g4", :sort_value=>"dateup"
    assert_global_values("g4", ["keyword"], "25", 'dateup')
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert(assigns(:subjects).length>0)
    assert_results
  end

  def test_pagination
    post :retrieve, :query=>{"string"=>"education"}
   post :retrieve_page, :query=>{"string"=>"education"}, :page=>"2"
    assert_template 'record/general'
    assert_equal ['education'], assigns["query"]
    assert_global_values("g2,g3")
    assert(assigns(:subjects).length>0)
    assert_results
  end
  
  def test_image_pagination
    post :retrieve,  :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>"images"
    post :retrieve_page, :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>"images", :page=>"2"
    assert_global_values("g3", ["keyword"], "25", 'relevance', [], 'images')
    assert_template 'record/images'
    assert_equal ['education'], assigns["query"]
    assert_results
  end
  
  def test_book_pagination
    post :retrieve, :query=>{"string"=>"education"}, :sets=>"g4"
    post :retrieve_page, :query=>{"string"=>"education"}, :sets=>"g4", :page=>"2"
    assert_global_values("g4", ["keyword"], "25")
    assert_template 'record/general'
    assert_equal ['education'], assigns["query"]
    assert(assigns(:subjects).length>0)
    assert_results
  end
  
  def test_material_filter_pagination
    post :retrieve, :query=>{"string"=>"water"}
    post :retrieve_page, :query=>{"string"=>"water"}, :filter=>"material_type:Book"
    post :retrieve_page, :query=>{"string"=>"water"}, :filter=>"material_type:Book", :page=>"2"
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g2,g3", ["keyword"], "25", 'relevance', [["material_type","Book"]])
    assert_results
  end
  
  def test_db_filter_pagination
    post :retrieve, :query=>{"string"=>"water"}
    post :retrieve_page, :query=>{"string"=>"water"}, :filter=>"material_type:Book/vendor_name:Oregon State University Library Catalog"
    post :retrieve_page, :query=>{"string"=>"water"}, :filter=>"material_type:Book/vendor_name:Oregon State University Library Catalog", :page=>"2"
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g2,g3", ["keyword"], "25", 'relevance', [["material_type","Book"],["vendor_name","Oregon State University Library Catalog"]])
    assert_results
  end
  
  def test_date_sort_pagination
    post :retrieve, :query=>{"string"=>"water"}
    post :retrieve_page, :query=>{"string"=>"water"}, :sort_value=>"dateup"
    post :retrieve_page, :query=>{"string"=>"water"}, :sort_value=>"dateup", :page=>"2"
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert_global_values("g2,g3", ["keyword"], "25", 'dateup')
    assert_results
  end
  
  def test_date_sort_images_pagination
    post :retrieve, :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>"images"
    post :retrieve_page, :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>"images", :sort_value=>"datedown"
    post :retrieve_page, :query=>{"string"=>"education"}, :sets=>"g3", :tab_template=>"images", :sort_value=>"datedown", :page=>"2"
    assert_global_values("g3", ["keyword"], "25", 'datedown', [], 'images')
    assert_template 'record/images'
    assert_equal ['education'], assigns["query"]
    assert_results
  end

  
  def test_date_sort_books_pagination
    post :retrieve, :query=>{"string"=>"water"}, :sets=>"g4"
    post :retrieve_page, :query=>{"string"=>"water"}, :sets=>"g4", :sort_value=>"dateup"
    post :retrieve_page, :query=>{"string"=>"water"}, :sets=>"g4", :sort_value=>"dateup", :page=>"2"
    assert_global_values("g4", ["keyword"], "25",'dateup')
    assert_template 'record/general'
    assert_equal ['water'], assigns["query"]
    assert(assigns(:subjects).length>0)
    assert_results
  end
  
   def test_retrieve_invalid_query
    post :retrieve,:query=>{"string"=>"asdlfowiesl"} 
    assert_template 'record/general'
    assert(assigns(:results).length==0)
    assert_tag :content=>"Your search did not return any results"
  end
  
  
end
