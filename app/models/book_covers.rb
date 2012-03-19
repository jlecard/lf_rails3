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

require 'net/http'
class BookCovers  < ActionController::Base
   attr_reader :coveruri
   def IsCover(isbn)
       if defined?(LIBRARYTHING_DEVKEY)
          begin
            @coveruri = 'http://covers.librarything.com/devkey/' + ::LIBRARYTHING_DEVKEY + '/small/isbn/' + isbn
            resource = Net::HTTP.new("covers.librarything.com",80)
            headers,data = resource.get('/devkey/' + ::LIBRARYTHING_DEVKEY + '/small/isbn/' + isbn)
            return headers.code 
 	  rescue
	    return 500
          end
       elsif defined?(OPENLIBRARY_COVERS)
          begin 
            resource = Net::HTTP.new("openlibrary.org", 80)
	    headers, data = resource.get("/api/search?q={%22query%22:%22(isbn_10:(" + isbn + ")%20OR%20isbn_13:(" + isbn + "))%22}&text=true")
            obj = self.safe_json_decode(data)
            bookresults = obj['result']
            bookversion = 1
	    if bookresults == nil: return 500 end
            if bookresults.length > 1 
              bookversion = bookresults.length
            end
            bookversion = bookversion -1
            bookkey = bookresults[bookversion]
            if bookkey == nil: return 500 end
            olnumber_begin = bookkey.index("/b/") + 3
            olnumber = bookkey.slice(olnumber_begin, bookkey.length-olnumber_begin)
            @coveruri = "http://covers.openlibrary.org/b/olid/" + olnumber + "-M.jpg"

	    # until someone can give me a better way to do this -- we are querying the 
	    # the data and seeing if the image is good or not
            # if it's a gif, it's no good.
            resource2 = Net::HTTP.new("covers.openlibrary.org", 80);
            headers2, data2 = resource2.get('/b/olid/' + olnumber + '-M.jpg')
            if data2.slice(0,3) == 'GIF'
              return 404
            else
              return headers.code
            end
	  rescue
	    return 500
	  end
       end
       return 500
   end

   # JSON.decode, or return {} if anything goes wrong.
   def safe_json_decode( json )
      return {} if !json
      begin
         ActiveSupport::JSON.decode json
      rescue ; {} end
   end
end
  

