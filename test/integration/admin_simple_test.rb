# $Id: admin_simple_test.rb 701 2007-01-26 08:18:10Z frumkinj $

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

require "#{File.dirname(__FILE__)}/../test_helper"

class AdminSimpleTest < ActionController::IntegrationTest
  fixtures :users, :collections, :collection_groups, :site_configs
  
  def setup
    login
  end
  
  def login
    admin = users(:admintest)
    post 'user/login', {:name => admin.name, :password => 'secret'}
  end
  

  # FIXME: the following are all stupid, temporary placeholders.  They're
  # here because rails doesn't allow functional tests to span controllers,
  # which means that we can't use the default scaffolded functional tests.
  # Which itself is no big thing, since they aren't that exciting anyway.
  # In the meantime these assure that the admin/* controllers are at least
  # working, and we can replace them as we replace the scaffold test code 
  # with our own UIs and tests for each controller. 
  # 
  # The whole suite of collection controller tests are left at the bottom
  # as an example of a whole scaffolded functional test suite, adapted for
  # our login system.  
  # 
  # -Dan

  def test_site_config_index
    get 'admin/site_config/index'
    assert_template 'list'
  end

  def test_site_config_list
    get 'admin/site_config/list'
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:site_configs)
  end

  def test_site_config_show
    get 'admin/site_config/show', :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:site_config)
    assert assigns(:site_config).valid?
  end

  def test_site_config_new
    get 'admin/site_config/new'
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:site_config)
  end

  def test_site_config_create
    num_site_configs = SiteConfig.count
    post 'admin/site_config/create', :site_config => {}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal num_site_configs + 1, SiteConfig.count
  end

  def test_site_config_edit
    get 'admin/site_config/edit', :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:site_config)
    assert assigns(:site_config).valid?
  end

  def test_site_config_update
    post 'admin/site_config/update', :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_site_config_destroy
    assert_not_nil SiteConfig.find(1)
    post 'admin/site_config/destroy', :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      SiteConfig.find(1)
    }
  end

  def test_user_index
    get 'admin/user/index'
    assert_template 'list'
  end

  def test_user_list
    get 'admin/user/list'
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:users)
  end

  def test_user_show
    get 'admin/user/show', :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:user)
    # FIXME: See note below
    #assert assigns(:user).valid?
  end

  def test_user_new
    get 'admin/user/new'
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:user)
  end

  def test_user_create
    num_users = User.count
    post 'admin/user/create', :user => {:name => 'joey', :password => 'secrete',
      :password_confirmation => 'secrete', :email => 'joey@example.com'}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal num_users + 1, User.count
  end

# FIXME: Not sure why these aren't working - probably something wrong with 
# validation logic in user.rb model.
# 
#  def test_user_edit
#    get 'admin/user/edit', :id => 1
#    assert_response :success
#    assert_template 'edit'
#    assert_not_nil assigns(:user)
#    assert assigns(:user).valid?
#  end
#
#  def test_user_update
#    post 'admin/user/update', :id => 1
#    assert_response :redirect
#    assert_redirected_to :action => 'show', :id => 1
#  end

  def test_user_destroy
    assert_not_nil User.find(1)
    post 'admin/user/destroy', :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      User.find(1)
    }
  end

  def test_collection_index
    get 'admin/collection/index'
    assert_template 'list'
  end

  def test_collection_list
    get 'admin/collection/list'
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:collections)
  end

  def test_collection_show
    good = collections(:collections_034)
    get 'admin/collection/show/%s' % good.id
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:collection)
    assert assigns(:collection).valid?
  end

  def test_collection_new
    get 'admin/collection/new'
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:collection)
  end

  def test_collection_edit
    good = collections(:collections_034)
    get 'admin/collection/edit/%s' % good.id
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:collection)
    assert assigns(:collection).valid?
  end

  def test_collection_update
    good_z = collections(:collections_034)
    post 'admin/collection/update/%s' % good_z.id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => good_z.id
  end

  def test_collection_destroy
    good_z = collections(:collections_034)
    assert_not_nil Collection.find(good_z.id)
    post 'admin/collection/destroy/%s' % good_z.id
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      Collection.find(good_z.id)
    }
  end

  def test_collection_group_index
    get 'admin/collection_group/index'
    assert_response :success
    assert_template 'list'
  end

  def test_collection_group_list
    get 'admin/collection_group/list'
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:collection_groups)
  end

  def test_collection_group_show
    get 'admin/collection_group/show', :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:collection_group)
    assert assigns(:collection_group).valid?
  end

  def test_collection_group_new
    get 'admin/collection_group/new'
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:collection_group)
  end

  def test_collection_group_create
    num_collection_groups = CollectionGroup.count
    post 'admin/collection_group/create', :collection_group => {}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal num_collection_groups + 1, CollectionGroup.count
  end

  def test_collection_group_edit
    get 'admin/collection_group/edit', :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:collection_group)
    assert assigns(:collection_group).valid?
  end

  def test_collection_group_update
    post 'admin/collection_group/update', :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_collection_group_destroy
    assert_not_nil CollectionGroup.find(1)
    post 'admin/collection_group/destroy', :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {CollectionGroup.find(1)}
  end


end
  
