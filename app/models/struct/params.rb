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
class Struct::Params < ActionWebService::Struct
  member :state_user, :string
  member :name_user, :string
  member :uuid_user, :string
  member :role_user, :string
  member :location_user, :string
  member :ip_user, :string
  member :group_user, :timestamp
  
  def initialize(request)
    super
    self.state_user = request.env['HTTP_STATE_USER']
    self.name_user = request.env['HTTP_NAME_USER']
    self.uuid_user = request.env['HTTP_UUID_USER']
    
    if !request.env['HTTP_ROLE_USER'].blank?
      self.role_user = request.env['HTTP_ROLE_USER'].split(",")
    end
    
    self.location_user = request.env[PROFIL_HTTP]
    
    if !request.env['HTTP_IP_USER'].blank?
      self.ip_user = request.env['HTTP_IP_USER'].split(",")
    end
    
    if !request.env['HTTP_GROUP_USER'].blank?
      self.group_user = request.env['HTTP_GROUP_USER'].split(",")
    end
    
  end
  
end