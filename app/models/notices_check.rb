# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Innovation
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


class NoticesCheck < ActiveRecord::Base    
  
  def self.getNotice(doc_id)
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(doc_id)
    if(doc_collection_id.blank? or doc_identifier.blank?)
      logger.error("Invalid notice id : #{doc_id} !!")
      return nil
    else
      return NoticesCheck.find(:first, :conditions => " doc_collection_id = #{doc_collection_id} and doc_identifier = '#{doc_identifier}' ")
    end
  end
  
  def self.addNotice(doc_id)
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(doc_id)
    if(doc_collection_id.blank? or doc_identifier.blank?)
      logger.error("Invalid notice id : #{doc_id} !!")
    else
      nc = NoticesCheck.new();
      nc.doc_collection_id = doc_collection_id;
      nc.doc_identifier = doc_identifier;
      nc.save;
      return nc;
    end
  end
  
  
  def self.deleteNotice(doc_id)
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(doc_id)
    if(doc_collection_id.blank? or doc_identifier.blank?)
      logger.error("Invalid notice id : #{doc_id} !!")
    else
      NoticesCheck.destroy_all(" doc_collection_id = #{doc_collection_id} and doc_identifier = '#{doc_identifier}' ")
      return true
    end      
  end
  
  
  def self.getNoticesByCollection(collection_id)
    notices = NoticesCheck.find_by_sql("SELECT doc_identifier FROM notices_checks WHERE doc_collection_id = #{collection_id} ")
    return notices;
  end
  
  
end
