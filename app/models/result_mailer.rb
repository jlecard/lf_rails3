# $Id: result_mailer.rb 1160 2007-11-17 00:07:29Z herlockt $

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

class ResultMailer < ActionMailer::Base
  include ApplicationHelper
  helper :application
  helper :record
  helper :cart
  
  def results(user_results, user_email)    
    @from       = LIBRARYFIND_EMAIL_USER
    @recipients = user_email
    @sent_on    = Time.now
    @subject    = 'Your LibraryFind records'
    @body["results"] = user_results
    @headers    = {}
    @content_type = "text/html"
  end
end
