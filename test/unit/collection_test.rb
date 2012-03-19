# $Id: collection_test.rb 975 2007-05-21 19:01:12Z herlockt $

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

class CollectionTest < Test::Unit::TestCase
  fixtures :collections

  def fetch_fixture (name)
    c = Collection.new(:name => collections(name).name,
      :conn_type => collections(name).conn_type,
      :host => collections(name).host,
      :record_schema => collections(name).record_schema,
      :mat_type => collections(name).mat_type)
  end

  def test_invalid_with_empty_attributes
    c = Collection.new
    assert !c.valid?
    assert c.errors.invalid?(:name)
    assert c.errors.invalid?(:conn_type)
    assert c.errors.invalid?(:host)
    # Don't test :mat_type; it defaults to Article so it should be valid
  end

  def test_bad_collection
    c = fetch_fixture :collections_034
    c.conn_type = 'Bad connection'
    c.record_schema = 'Bad schema'
    c.mat_type = 'Bad mat_type'
    assert !c.valid?
    assert c.errors.invalid?(:conn_type)
    assert_equal "Invalid material type", c.errors.on(:mat_type)

    c.conn_type = 'z3950'
    c.record_schema = 'Marc21'
    c.mat_type = 'Article'
    #Why isn't this working?
    # assert !c.valid?
  end
  
  def test_find_protocol
    c = fetch_fixture :collections_034
    # Why isn't this working?
    #assert !c.valid?
    assert !c.errors.invalid?(:name)
    assert !c.errors.invalid?(:conn_type)
    assert !c.errors.invalid?(:host)
    assert !c.errors.invalid?(:record_schema)
    assert_equal 'oasis.oregonstate.edu', c.find_protocol
  end

  def test_find_resources_simple
    
  end
  
  
end

