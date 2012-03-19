# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org

class Theme < ActiveRecord::Base
  
  def initialize()
    super
    @name_to_root = ""
  end
  
  def name_to_root
    if @name_to_root.blank?
      @name_to_root = calculate_theme()
    end
    
    return @name_to_root
  end
  
  def calculate_theme()
    if self.parent.nil? or self.parent == nil
        return self.label
      else
        _t = Theme.find(:first, :conditions => ["reference = ?", self.parent])
        return _t.calculate_theme + THEME_SEPARATOR + self.label
    end
  end
end