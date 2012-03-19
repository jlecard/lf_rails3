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
class Struct::ListItem < ActionWebService::Struct
  member :id, :string
  member :identifier, :string
  member :title, :string
  member :ptitle, :string
  member :isbn, :string
  member :type, :integer
  member :rank, :integer
  member :author, :string
  member :notes_count, :integer
  member :notes_avg, :float
  member :comments_count, :integer
  member :is_available, :boolean
  member :examplaires, [Struct::Examplaire]
  
  def initialize
    super
    self.id = "";
    self.identifier = "";
    self.title = "";
    self.type = "";
    self.author = "";
    self.notes_avg = 0
    self.comments_count = 0
    self.notes_count = 0
    self.ptitle = ""
    self.isbn = ""
    self.is_available = false
    self.examplaires = []
    self.rank = 0;
  end
  
  
end
