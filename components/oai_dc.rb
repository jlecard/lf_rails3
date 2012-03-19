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

require 'oai'

class OaiDc
  include OAI::XPath
  attr_accessor :title, :creator, :subject, :description, :publisher,
  :relation, :date, :type, :format, :contributor,
  :identifier, :source, :language, :coverage, :rights, :thumbnail
  
  def parse_metadata(element)
    
    labels = self.metadata_list()
    
    if element == nil: return nil end
    labels.each do |item|
      x = 0
      begin
        tmp_element  = element.metadata.xpath("./*/*[local-name()='" + item + "']")
      rescue
        next
      end
      if tmp_element != nil
        item = item.gsub('dc:','')
        eval("@" + item + " = []")
        tmp_element.each do |i|
          s = nil
          case parser_type(i)
            when 'libxml'
            s = i.content  
            when 'nokogiri'
            s = i.content 
            when 'rexml'
            s = i.text
          end
          
          if s != nil
            eval("@" + item + "[" + x.to_s + '] = ' +  s.dump )
            x += 1
          end 
          
        end
      end
      
      if x==0: eval('@' + item + '[' + x.to_s + '] = nil') end
    end
  end
  
  def metadata_list()
    labels = ['title','creator',
                'subject','description',
                'publisher','relation',
                'date','type','format',
                'contributor','identifier',
                'source','language',
                'coverage','rights','thumbnail']
  end
end
