# $Id: collection_group.rb 1012 2007-07-13 06:58:03Z reeset $

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

class CollectionGroup < ActiveRecord::Base
  
  has_many :collection_group_members, :dependent => :destroy
  has_many :collections, :through => :collection_group_members
  has_many :editorial_group_members, :dependent => :destroy
  has_many :editorials, :through => :editorial_group_members
  has_many :searchTabSubjects, :dependent => :nullify
  belongs_to :search_tab, :foreign_key => :tab_id

  def self.get_all(bool_advanced=false)
    advanced = "" #tab_id > 0 "
    if bool_advanced
	     advanced += "and display_advanced_search = 1"
    end
    return CollectionGroup.find(:all, :conditions => advanced, :order => 'tab_id, rank')
  end

  def self.get_item(id) 
    begin
      return CollectionGroup.find(id)
    rescue
      return nil
    end
  end

  def self.get_item_by_name(name)
    return CollectionGroup.find(:all, :conditions => "name='#{name}'")
  end

  def self.get_members(id)
    return CollectionGroupMember.find(:all, :conditions => "collection_group_id=#{id.to_i}")
  end

  def self.get_parents(id)
    return CollectionGroupMember.find(:all, :conditions => "collection_id=#{id.to_i}")
  end
  
  def self.getCollectionGroupFullNameById(cg_id)
    cg = CollectionGroup.find(:first, :conditions => " id = #{cg_id.to_i}")
    if(!cg.nil?)
      return cg.full_name
    else
      return "None"
    end
    
  end
end
