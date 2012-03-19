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

require 'net/https'
require 'uri'
require 'rexml/document'

class GoogleSpell  < ActionController::Base
  def GetWords(phrase)
    results = [] 
    x = 0
    i = 0
    
    phrase = phrase.downcase 
    if (phrase.slice(2,1)==":") 
      phase = phase.slice(3, phrase.length-3)
    end
    phrase = phrase.gsub("&", "&amp;")
    phrase = phrase.gsub("<", "&lt;")
    phrase = phrase.gsub(">", "&gt;")
    word_frag = phrase.split(" ")
    word_frag.each do |lookup|
      words = "<spellrequest textalreadyclipped=\"0\" ignoredups=\"1\" ignoredigits=\"1\" ignoreallcaps=\"0\"><text>" + lookup + "</text></spellrequest>"
      gword = Hash.new()
      gword["original"] = lookup;
      gword["data"] = ""
      
      # gestion proxy
      if (ENV['PROXY_URL'] != "")
        http = Net::HTTP.Proxy(ENV['PROXY_URL'].to_s, ENV['PROXY_PORT'].to_s).new('www.google.com', 443)
      else
        http = Net::HTTP.new('www.google.com', 443)
      end
      
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response =  http.start {|net|
        net.request_post("/tbproxy/spell?lang=fr", words) {|response|
          doc = REXML::Document.new response.body
          nodelist = doc.elements.to_a("//c")
          nodelist.each do |item|
            if item!=nil
              tmpnodetext = item.text.split(" ")
              if tmpnodetext[0].downcase != gword["original"].downcase
                gword["data"] = item.text.downcase
              else
                gword["data"] = ""
              end
            end
          end
        }
      }
      results << gword
    end
    
    return results
  end
end

