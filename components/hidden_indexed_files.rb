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
# Create a file which contains a medias list having some missing meta-datas needed
require 'rexml/document'
include REXML

class HiddenIndexedFiles
  
  def initialize(dbName = "inconnue", logger=nil)
    # Create a file CSV with the database name
    @fileNameCSV = dbName
    @limit = 0
    @CSV = nil
    @SEPARATOR = "\t"
    @RETURN = "\n\r"
    @logger = logger
  end
  
  def checkRow(id="", media="")
    # Check if the title and the type are present
    if @limit < 5000
      if (media.title.blank?) or (media.type.blank?) or (media.theme.blank?)
        @limit += 1
        addMedia(id, media)
      end
    end
  end
  
  def addMedia(id="", media="")
    begin
      @logger.debug("[addMedia] id: #{id} media: #{media}")
      if @CSV.nil?
        @CSV = "REJECT#{@SEPARATOR}DB#{@SEPARATOR}ID#{@SEPARATOR}TITLE#{@SEPARATOR}CREATOR#{@SEPARATOR}SUBJECT#{@SEPARATOR}DESCRIPTION#{@SEPARATOR}PUBLISHER#{@SEPARATOR}CONTRIBUTOR#{@SEPARATOR}DATE#{@SEPARATOR}TYPE#{@SEPARATOR}THEME#{@SEPARATOR}FORMAT#{@SEPARATOR}IDENTIFIER#{@SEPARATOR}SOURCE#{@SEPARATOR}RELATION#{@SEPARATOR}COVERAGE#{@SEPARATOR}RIGHTS#{@RETURN}"
      end
      
      @CSV += Time.now().strftime("%m/%d/%Y %H:%M:%S") + @SEPARATOR
      @CSV += id.to_s + @SEPARATOR
      @CSV += media.id.to_s + @SEPARATOR
      
      if media.title.blank?
        @CSV += "Manquant" + @SEPARATOR
      else
        @CSV += media.title.to_s + @SEPARATOR
      end
      
      @CSV += media.creator.to_s + @SEPARATOR
      @CSV += media.subject.to_s + @SEPARATOR
      @CSV += media.description.gsub("\n","").gsub("\t","").gsub("\r","").to_s + @SEPARATOR
      @CSV += media.publisher.to_s + @SEPARATOR
      @CSV += media.contributor.to_s + @SEPARATOR
      @CSV += media.date.to_s + @SEPARATOR
      
      if media.type.blank?
        @CSV += "Manquant" + @SEPARATOR
      else
        @CSV += media.type.to_s + @SEPARATOR
      end
      
      if media.theme.blank?
        @CSV += "Manquant" + @SEPARATOR
      else
        @CSV += media.theme.to_s + @SEPARATOR
      end
      
      @CSV += media.format.to_s + @SEPARATOR
      @CSV += media.identifier.to_s + @SEPARATOR
      @CSV += media.source.to_s + @SEPARATOR
      @CSV += media.relation.to_s + @SEPARATOR
      @CSV += media.coverage.to_s + @SEPARATOR
      @CSV += media.rights.to_s + @RETURN
    rescue => err
      @logger.error("[HiddenIndexedFiles]" + err.message)
      @CSV += @RETURN
    end
  end
  
  def validList
    
    if !@CSV.blank?
      begin
        reject = Reject.new();
        reject.name = @fileNameCSV;
        reject.data = @CSV;
        reject.save!;
      rescue => e
        @logger.error("[validList] error : #{e.message}")
      end
    end
  end
  
end
