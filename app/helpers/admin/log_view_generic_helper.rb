# $Id$

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

module Admin::LogViewGenericHelper
  
  def format_date_stats(item, separator = "/")
    str = ""
    
    if (!item.nil?)
      ["day","month","year"].each do |d|
        if !item[d].blank?
          if (item[d].to_i < 10)
            str += "0"
          end
          str += "#{item[d]}"
          if (d != "year")
            str += separator
          end
        end
      end
    end
    return str
  end
  
  def get_label_gc(dico, gid)
    if (dico.nil? or dico.empty?)
      return gid
    end
    
    gid = gid.gsub("g","")
    
    dico.each do |gc|
      if (gc.id == gid.to_i)
        return "#{gc.full_name} (#{gc.id})"
      end
    end
  end
  
  def get_label_search_tab_subject(dico, id)
    if (dico.nil? or dico.empty?)
      return id
    end
    
    dico.each do |elt|
      if (elt.id == id.to_i)
        
        if (elt.parent_id == 0)
          return elt.label
        else 
          return "#{get_label_search_tab_subject(dico, elt.parent_id)} > #{elt.label}"
        end
      end
    end
  end
end
