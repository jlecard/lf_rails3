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
class Examplaire
  attr_accessor :id, :number, :call_num, :location, :label,:collection_id,
                :dc_identifier, :availability, :link_label, :launch_url,
                :link, :support, :metadata_id, :barcode, :source,
                :object_id, :document_id
  def initialize(args=nil)
    if !args
      self.id = 0
      self.number = ""
      self.availability = false
      self.call_num = ""
      self.location = ""
      self.label = ""
      self.collection_id =""
      self.dc_identifier = ""
      self.link_label = ""
      self.launch_url = ""
      self.link = ""
      self.support = ""
    else
      args.each do |key, value|
        instance_variable_set("@#{key}",value)
      end  
    end
  end

end
