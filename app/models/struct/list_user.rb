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
class Struct::ListUser < ActionWebService::Struct
  member :id, :string
  member :title, :string
  member :ptitle, :string
  member :description, :string
  member :state, :integer
  member :date_created, :timestamp
  member :date_updated, :timestamp
  member :size, :integer
  member :tags_count, :integer
  member :tags_weight_sum, :integer
  member :comments_count, :integer
  member :comments_view_count, :integer
  member :object_tag_struct, Struct::ObjectTagStruct
  member :uuid, :string
  member :user_name, :string
  member :notices, [Struct::ListItem]
  
  def initialize
    super
    self.id = "";
    self.ptitle = "";
    self.title = "";
    self.description = "";
    self.state = 0;
    self.date_created = nil;
    self.date_updated = nil
    self.size = 0
    self.tags_count = 0
    self.tags_weight_sum = 0
    self.comments_count = 0
    self.comments_view_count = 0
    self.object_tag_struct = nil
    self.uuid = "";
    self.user_name = "";
    self.notices = []
  end
  
end
