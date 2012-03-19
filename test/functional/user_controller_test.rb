# $Id: user_controller_test.rb 848 2007-03-13 23:29:18Z herlockt $

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
require 'user_controller'

# Re-raise errors caught by the controller.
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < Test::Unit::TestCase
  fixtures :users

  def setup
    @controller = UserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_template 'index'
  end

  def test_bad_login
    admin = users(:admintest)
    post :login, :name => admin.name, :password => 'wrong_secret'
    assert_template "login"
    assert_equal "Invalid user or password", flash[:error]
  end

  def test_good_login
    admin = users(:admintest)
    post :login, :name => admin.name, :password => 'secret'
    assert_redirected_to :controller => 'record', :action => 'search'
    assert_equal admin.id, session[:user_id]
  end
  
  def test_logout
    admin = users(:admintest)
    post :login, :name => admin.name, :password => 'secret'
    assert_redirected_to :controller => 'record', :action => 'search'
    assert_equal admin.id, session[:user_id]
    get :logout
    assert_redirected_to :controller => 'record', :action => 'search'
    assert_nil session[:user]
  end
  
end
