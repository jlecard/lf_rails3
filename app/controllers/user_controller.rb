# $Id: user_controller.rb 1160 2007-11-17 00:07:29Z herlockt $

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
 
class UserController < ApplicationController
  layout "libraryfind"
  include ApplicationHelper

 def index
    render :action => 'login'
  end


  def login
    session[:user_id] = nil
    logger.debug("before post")
    if request.post?
      logger.debug("after post")
      result = false
#      if LDAP_ENABLE
#        result = LdapUser.authenticate(params[:user][:name], params[:user][:password])
#        logger.info("[UserController] login: result => #{result}")
#        if result
#          user = User.find_by_name(params[:user][:name])
#        end
#      end
      if !result
        user = User.authenticate(params[:user][:name], params[:user][:password])
      end
      
      if user
        session[:user] = user
        session[:user_id] = user.id
        # If the user had requested a specific restricted page, send them there
        uri = session[:original_uri]
        session[:original_uri] = nil
        redirect_to(uri || {:controller => '/record', :action => 'search'})
      else
        flash[:error] = translate('INVALID_USER')
      end
    end
  end
  
  def logout
    reset_session
    flash[:notice] = translate('LOGGED_OUT')
    redirect_to(:controller => '/record', :action => 'search')
  end
  
end
