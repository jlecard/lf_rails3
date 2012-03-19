# $Id: cached_record.rb 694 2007-01-26 07:16:36Z frumkinj $

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

require 'cached_search'
require 'collection_group_member'

class CachedRecord < ActiveRecord::Base
  belongs_to :search
  belongs_to :collection
  
  # collection_set here is an integer
  def self.deleteCachedRecord(query_string, query_type, collection_set)
    cs = CachedSearch.find(:first, :conditions => " query_string = '#{query_string}' AND query_type = '#{query_type}' ")
    if !cs.nil?
      groupes = CollectionGroup.find(collection_set)
      groupes.collections.each do |col_id|
        CachedRecord.delete(:first => " search_id = #{cs.id} and collection_id = '#{col_id.id}' ")  
      end
    end      
  end
  
end
