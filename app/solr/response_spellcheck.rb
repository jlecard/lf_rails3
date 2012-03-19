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
########################################
# Overloading solr  spellcheck         #
#  for mathching with own request      #
########################################

require 'solr'


class Solr::Response::SpellcheckCompRH < Solr::Response::Ruby
  attr_reader :suggestions
  
  def initialize(ruby_code)
    super(ruby_code)
    @suggestions = @data['suggestions']
  end
  
  def get_response()
    if ((@data.blank?) || (@data["spellcheck"].blank?) ||
     (@data["spellcheck"]["suggestions"].blank?))
      return ([]);
    end
    
    tmp 		= Array.new();
    results = Array.new();
    tmp 		|= (@data["spellcheck"]["suggestions"]);
    tmp.each do |suggestions|
      if (suggestions.class == Hash)
        suggestions.each do |elementOfArray|
          if (elementOfArray[0] == "suggestion")
            listSuggest = elementOfArray[1];
            if listSuggest.class == Array
              listSuggest.each do |hashSuggest|
                results << hashSuggest["word"];
              end
            else
              results << listSuggest["word"];
            end
          end
        end
      end
    end
    
    index = tmp.index("collation")
    if ((!index.nil?) && (tmp.length() >= (index + 1)))
      results.insert(0, tmp[index + 1]);
    end
    return (results);
  end
end
