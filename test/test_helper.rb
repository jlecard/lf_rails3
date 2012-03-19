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

ENV["RAILS_ENV"] = "test"
require 'action_web_service/test_invoke'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'


class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
 def assert_defaults
    assert_equal '25', assigns["max"]
    assert_equal ["keyword"], assigns["type"]
    assert_equal "0", assigns["start"]
    assert_equal 'relevance', assigns["sort_value"]
    assert_equal [], assigns["filter"]
    assert_equal 'general', assigns["tab_template"]
    
  end
  
  def assert_global_values(_sets="g2,g3", _type=["keyword"], _max="25", _sort_value="relevance", _filter=[], _tab_template="general",  _start="0")
    assert_equal _sets, assigns["sets"]
    assert_equal _type, assigns["type"]
    assert_equal _start, assigns["start"]
    assert_equal _max, assigns["max"]
    assert_equal _sort_value, assigns["sort_value"]
    assert_equal _filter, assigns["filter"]
    assert_equal _tab_template, assigns["tab_template"]
  end
  
end
