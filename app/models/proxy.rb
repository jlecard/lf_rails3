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


#==============================================
# this proxy will generally work with ezproxy 
# or III's wam.
#==============================================
class Proxy
  def GenerateProxy(s)
     if s.index(LIBRARYFIND_PROXY_ADDRESS)!=nil: return s end

     case LIBRARYFIND_PROXY_TYPE
         when "WAM"
	    return GenerateProxyIII(s)
         when "EZPROXY"
	    return GenerateProxyEZ(s)
         else
	    return s
      end
  end


  def GenerateProxyEZ(s)
     s = LIBRARYFIND_PROXY_ADDRESS + s
     return s;
  end

  def GenerateProxyIII(s)
    objMatches = nil
    stem = ""
    returnUrl = ""
    port = "0"

    if s.slice(0,1) == '/': s = LIBRARYFIND_BASEURL end
    if s.index("http://")!=nil
      objMatches = s.match(/http:\/\/(.*?):{0,1}([0-9]*)(\/)(.*)/)
      stem = "http://"
    else
      objMatches = s.match(/https:\/\/(.*?):{0,1}([0-9]*)(\/)(.*?)/)
      stem = "https://"
    end

    if objMatches != nil
      port = objMatches[2] if objMatches[2] != nil
      port = 0 if objMatches[2] == nil
      if port == "": port = "0" end

      if objMatches[1].length != 0
        slash = ""
        if LIBRARYFIND_PROXY_ADDRESS.index("/")==nil
           slash = "/"
        end
        returnUrl = port + "-" + objMatches[1] + LIBRARYFIND_PROXY_ADDRESS + slash +  objMatches[4]
      else
        returnUrl = port + "-" + s.slice(stem.length, (s.length-stem.length)) + LIBRARYFIND_PROXY_ADDRESS
      end
    else
      returnUrl = port + "-" + s.slice(stem.length, (s.length-stem.length)) + LIBRARYFIND_PROXY_ADDRESS
    end
    return stem + returnUrl;
  end
end

