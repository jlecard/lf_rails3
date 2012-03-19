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
if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "" end
require ENV['LIBRARYFIND_HOME'] + 'components/mediaview/bpi_connector'

class MetaDisplay < ActionController::Base
  INFOS_USER_CONTROL = nil
  # return: Record || nil if error
  # idSearch could be nil for harvested document
  #
  def display(idDoc, idCollection, idSearch, infos_user = nil)
    # indicate it the doc is internal in order to log it for the stats
    
    if idDoc == nil || idCollection == nil || idDoc == "" || idCollection == ""
      logger.debug("idDoc OR idCollection not defined")
    end
    _collection = Collection.find(idCollection)
    if _collection == nil
      logger.debug("Cannot find collection id : #{idCollection}")
      return (nil);
    end
    _type = _collection.conn_type.capitalize
    if _type == 'Connector'
      _type = _collection.oai_set.capitalize
    end
    _res = Record.new
    begin 
      idSearch = idSearch == nil || idSearch == "" ? 0 : idSearch
      eval("_res = #{_type}SearchClass.GetRecord('#{idDoc}', '#{idCollection}', '#{idSearch}', infos_user)")
    rescue Exception=>e
      logger.error("Error while generating #{_type}SearchClass : #{$!} => #{e.message}")
      logger.error("#{_type}SearchClass : #{e.backtrace.join("\n")}}")
      _res = nil
    end
    if _res == nil
      logger.debug("No document found for idDoc = #{idDoc} and idCollection=#{idCollection}")
    end
    
    # control droit
    if(!_res.nil? and INFOS_USER_CONTROL and !infos_user.nil?)
      droits = ManageDroit.GetDroits(infos_user, idCollection)
      if(droits.nil?)
        logger.debug("No rigth for this document")
        _res = nil
      elsif(droits.id_perm != ACCESS_ALLOWED)
        _res.direct_url = ""
      end
    end
    
    return _res
  end    
  
  def getMediaviewDocument(idDoc, idCollection, idSearch)
    if idDoc == nil || idCollection == nil || idDoc == "" || idCollection == ""
      logger.debug("idDoc OR idCollection not defined")
      return nil
    end
    _collection = Collection.find(idCollection)
    logger.debug("Collection type:" + _collection.conn_type.to_s)
    if _collection != nil && _collection.conn_type == "mediaview"
      md = MediaviewDocument.new
      bpi = Bpi_connector.new
      _conn = bpi.connect_to_postgresql(_collection.name, _collection.host, _collection.user, _collection.pass)
      # TODO: Check if document type is website
      _sourceDetails = bpi.get_document_source(_conn, idDoc)
      
      md.object = _sourceDetails[0]
      logger.debug("Object type :" + md.object.to_s)
      _sources = _sourceDetails[1]
      #logger.debug("SOURCE_DETAILS : " + _sources.to_s)
      #logger.debug("source = " + _sources[0].to_s)
      i= 0
      _source = _sources[0]
      while i < _sources.length do
        if i != _sources.length-1
          _source += ";"
        end
        i+= 1
        _source += _sources[i].to_s          
      end
      
      if md.object == "Web"
        md.sourceUrl = _source
        #logger.debug("Source of the document:"+ md.sourceUrl)
      else 
        md.source = _source
      end
      
      return md # if the document is from MediaView DataBase
      
    else
      return nil # if the document is not from MediaView Database
    end
  end  
  
end
