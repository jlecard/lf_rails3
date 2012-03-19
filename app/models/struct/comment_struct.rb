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
class Struct::CommentStruct < ActionWebService::Struct
  member :id,                  :integer
  member :comment_date,        :datetime
  member :content,             :string     
  member :comment_relevance,   :integer
  member :dont_like_count,     :integer
  member :like_count,          :integer
  member :user_name,           :string
  member :user_type,           :string
  member :uuid,                :string
  member :note,                :integer
  member :title,               :string
  member :state,               :integer
  member :parent_id,           :integer
  member :object_uid,          :string
  member :object_type,         :integer
  member :object_title,        :string
  member :alert,            [Struct::AlertsStruct]
  member :comment_children, [Struct::CommentStruct]
  
  def initialize
    super
    self.id = 0;
    self.comment_date = Time.new;
    self.content = "";
    self.comment_relevance = 0;
    self.user_name = "";
    self.user_type = "";
    self.uuid = "";
    self.note = 0;
    self.title = "";
    self.state = 0;
    self.object_title = "";
    self.object_uid = "";
    self.object_type = "";
    self.alert = []
    self.comment_children = []
  end
  
end