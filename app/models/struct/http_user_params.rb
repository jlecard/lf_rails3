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
class HttpUserParams
  attr_accessor :state_user
  attr_accessor :name_user
  attr_accessor :uuid_user
  attr_accessor :role_user
  attr_accessor :location_user
  attr_accessor :ip_user
  attr_accessor :group_user
  
  def initialize args
    args.each do |key, val|
      instance_variable_set("@#{key}", val) unless val.nil?
    end
  end
  
  def self.from_http_request(request)
    info_user = HttpUserParams.new
    info_user.state_user = request.env['HTTP_STATE_USER']
    info_user.name_user = request.env['HTTP_NAME_USER']
    info_user.uuid_user = request.env['HTTP_UUID_USER']
    info_user.location_user = request.env[PROFIL_HTTP]
    info_user.role_user = request.env['HTTP_ROLE_USER'].split(",") if !request.env['HTTP_ROLE_USER'].blank?
    info_user.ip_user = request.env['HTTP_IP_USER'].split(",") if !request.env['HTTP_IP_USER'].blank?
    info_user.group_user = request.env['HTTP_GROUP_USER'].split(",") if !request.env['HTTP_GROUP_USER'].blank?
    return info_user
  end
  
end