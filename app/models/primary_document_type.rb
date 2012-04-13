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
class PrimaryDocumentType < ActiveRecord::Base
  
  validates_uniqueness_of :name
  
  before_update { |primary_document_type|
    begin
      pdtn = ""
      cndt = ""
      if (!primary_document_type.nil?)
        old_name = getPrimaryDocumentTypeNameById(primary_document_type.id)
        if (old_name != primary_document_type.name)
          #get all id of doc_type who have primary_doc_type = id
          dt_ids = DocumentType.getDocTypeIdByPrimaryId(primary_document_type.id)
          #parcours tout les doc_type_id et modifie le doctype de la notice
          conditions = ""
          turn = 0
          for id in dt_ids
            if (turn != 0)
              #conditions += " or"
              conditions = "#{conditions} or"
            end
            #conditions += " document_type_id = '#{id.id}'"
            conditions = "#{conditions} document_type_id = '#{id.id}'"
            turn += 1
          end
          pdtn = primary_document_type.name
          cndt = conditions
          #logger.debug("[PrimaryDocumentType] Primary Document Type Name: #{primary_document_type.name} conditions:#{conditions}")
          Notice.update_all("dc_type = '#{primary_document_type.name.gsub(/'/, "\\\\'")}'", "#{conditions}")
          #Notice.update_all("dc_type = '#{primary_document_type.name}'")
        end
      end
    rescue => e
        logger.error("[PrimaryDocumentType][before_update]: " + e.message)
        raise e
    end
  }
  
  def self.getPrimaryDocumentTypeNameById(pdt_id)
    pdt = PrimaryDocumentType.find(:first, :conditions =>"id = #{pdt_id.to_i}")
    if(!pdt.nil?)
      return pdt.name
    else
      return 'None'
    end
  end
  
  def self.getNameByDocumentType(dtype,collection_id)
    value = dtype
    dtype_sql = sanitize(['?', dtype])
    if !dtype.blank?
      res = PrimaryDocumentType.find_by_sql("SELECT primary_document_types.name AS name, primary_document_types.id AS id FROM primary_document_types,document_types WHERE document_types.name = #{dtype_sql} AND document_types.collection_id = #{collection_id} AND primary_document_types.id = document_types.primary_document_type limit 1")
      if !res.nil? and !res.empty?
        if res[0].id != 1
          logger.debug("[PrimaryDocumentType] res : #{res[0].inspect}")
          value = res[0].name
        else
          value = dtype
        end
      else
        p = DocumentType.new
        p.name = dtype
        p.collection_id = collection_id
        p.save!
        value = dtype
      end
    else
      value = ""
    end
    logger.debug("[PrimaryDocumentType] [getNameByDocumentType] type: #{dtype} collection:#{collection_id} return : #{value}")
    return value
  end
  
  
  
end
