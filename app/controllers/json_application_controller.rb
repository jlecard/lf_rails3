# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Innovation
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

class JsonApplicationController < ApplicationController
  include ApplicationHelper
  
  before_filter :analyse_request
  
  # == Analyse parameters in http header
  #
  # if INFOS_USER_CONTROL is true in lf.rb, these variables in HTTP Header are required :
  #  
  # * <b>HTTP_STATE_USER</b> = State User (connected or anonymous) : Value = True/False
  # * <b>HTTP_NAME_USER</b> = Name User (pseudo) : Value = String
  # * <b>HTTP_UUID_USER</b> = Uuid USER (CommunityUser.uuid) : Value = String
  # * <b>HTTP_ROLE_USER</b> = Role User : Value = String Array
  # * <b>PROFIL_HTTP</b> = Profil User : Value = String
  # * <b>HTTP_IP_USER</b> = Ip : Value = String
  # * <b>HTTP_GROUP_USER</b> = Group User : Value = String Array
  #
  def analyse_request
    # get info user for header
    @info_user = nil
    logger.debug("[JsonApplicationController] STATE_USER : #{request.env['HTTP_STATE_USER']}")
    logger.debug("[JsonApplicationController] NAME_USER : #{request.env['HTTP_NAME_USER']}")
    logger.debug("[JsonApplicationController] UUID_USER : #{request.env['HTTP_UUID_USER']}")
    logger.debug("[JsonApplicationController] ROLE_USER : #{request.env['HTTP_ROLE_USER']}")
    logger.debug("[JsonApplicationController] LOCATION_USER : #{request.env[PROFIL_HTTP]}")
    logger.debug("[JsonApplicationController] IP_USER : #{request.env['HTTP_IP_USER']}")
    logger.debug("[JsonApplicationController] GROUP_USER : #{request.env['HTTP_GROUP_USER']}")
    if !request.env['HTTP_STATE_USER'].blank?
      @info_user = Struct::Params.new(request)
    end
    logger.debug("[JsonApplicationController] [analyse_request] @info_user : #{@info_user.inspect}")
    $objDispatch.setInfosUser(@info_user)
    $objCommunityDispatch.setInfosUser(@info_user)
    $objAccountDispatch.setInfosUser(@info_user)
  end
  
end
