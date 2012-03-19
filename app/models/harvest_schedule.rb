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

class HarvestSchedule < ActiveRecord::Base
  belongs_to :collection
  validates_columns :day, :time
  attr_accessor :collection_name
  #validates_uniqueness_of :day, :scope=>:time, :scope=>:collection_id
  
  # Caution: Returns an array : you cannot access an index with enum_values[n]
  # enum_values[n] returns an Array {key, value}
  def enum_values
    enum_values = {1=>"Monday",2=>"Tuesday",3=>"Wednesday",4=>"Thursday",5=>"Friday",6=>"Saturday", 7=>"Sunday"}
    return enum_values.sort
  end
  
end
