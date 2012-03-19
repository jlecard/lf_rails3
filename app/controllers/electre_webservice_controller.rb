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

# Conf var a add
# userName, userPassword, proxyAdr, proxyPort
#

class ElectreWebserviceController < ApplicationController
  
  def index # my training
    webService  = ElectreWebservice.new(ActiveRecord::Base.logger)
    isbn        = 'ElectreWebserviceController'
    isbn        = params[:id] || isbn
    @more       = webService.getSessionToken
    @return     = ""
    @return     = webService.back_cover(isbn)
    @return     += webService.table_of_contents(isbn)
    @return     += '<img src="/electre_webservice/show_image/' + isbn + '" />'
    @return     += "Return of image?" + webService.image?(isbn).to_s

    render(:action => 'index')
  end
  
  def show_image()
    begin
        webService = ElectreWebservice.new(ActiveRecord::Base.logger)
        isbn = params[:id]
              
        send_data(webService.image(isbn), :type => 'image/jpg', :disposition => 'inline') # type legerement arbitraire tester sous firefox
    rescue => err
        logger.error("[show_image] " + err.message.to_s)
    end
  end
end
