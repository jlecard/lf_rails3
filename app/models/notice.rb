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

require 'rubygems'
require 'composite_primary_keys'

class Notice < ActiveRecord::Base
  
  set_primary_keys :doc_identifier, :doc_collection_id
  
  has_many :user_records,   :foreign_key => [:doc_identifier, :doc_collection_id], :dependent => :destroy
  
  has_many :subscriptions,  :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_NOTICE} "
  
  has_one   :objects_count, :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_NOTICE} "
  
  has_many :comments,       :foreign_key => :object_uid,  :dependent => :destroy,  :conditions => " object_type = #{ENUM_NOTICE} "
  
  has_many :objects_tags,   :foreign_key => :object_uid,  :dependent => :destroy,  :conditions => " object_type = #{ENUM_NOTICE} "
  
  after_create { |notice| 
    # create count for notice
    ObjectsCount.createCount(ENUM_NOTICE, notice.id) 
  }
  
  
  # doc is idDoc;idColl[;idSearch]
  def self.existsById?(doc)
    idDoc, idColl = UtilFormat.parseIdDoc(doc)
    return Notice.exists?("#{idDoc},#{idColl}")
  end
  
  def self.addOnlyNoExist(record)
    if !existsById?(record.id)
      return addNotice(record) 
    else
      return nil
    end
  end
  
  def self.getListInfosCopy(doc_id)
    logger.debug("[Notice][getListInfosCopy] #{doc_id}")
    ## todo implement
    return true
  end
  
  
  def self.getNoticeByDocId(object_uid)
    logger.debug("[Notice][getNoticeByDocId] #{object_uid}")
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(object_uid);
    if doc_identifier.blank? or doc_collection_id.blank?
      logger.error("[Notice][getNoticeByDocId] invalid object_uid: #{object_uid}")
      return nil
    end
    return Notice.find(:first, :conditions => " doc_identifier='#{doc_identifier}' and doc_collection_id=#{doc_collection_id} ");
  end
  
  def self.topByListe(page = 1, max=10)
    return self.topByChamps("lists_count", page, max) 
  end
  
  def self.topBySubscription(page = 1, max=10)
    return self.topByChamps("subscriptions_count", page, max) 
  end
  
  def self.topByComment(page = 1, max=10)
    return self.topByChamps("comments_count", page, max) 
  end
  
  def self.topByTag(page = 1, max=10)
    return self.topByChamps("tags_count", page, max) 
  end
  
  def self.topByNote(page = 1, max=10)
    
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    # select => 
    res = Notice.find_by_sql("select SQL_CALC_FOUND_ROWS * from notices n, collections c
    where notes_count > 0
    and n.doc_collection_id = c.id  
    order by notes_avg DESC, notes_count DESC limit #{offset}, #{max}")
    
    total = 0
    count = Notice.find_by_sql("SELECT FOUND_ROWS() as total")
    if (!count.nil? and !count.empty?)
      total = count[0].total
    end
    
    tab = []
    res.each do |v|
      hash = Hash.new()
      v.attributes.each do |k, v|
        hash[k] = v
      end
      tab << hash
    end
    
    return {:result => tab, :count => total, :page => page, :max => max}
  end
  
  private
  def self.addNotice(record)
    if !record.nil?
      idDoc, idColl = UtilFormat.parseIdDoc(record.id)
      dt_id = DocumentType.getDocumentTypeId(record.material_type, idColl)
      notice = Notice.new(:doc_identifier => idDoc, :doc_collection_id => idColl, :created_at => DateTime::now(), :dc_title => record.ptitle, :dc_author => record.author, :dc_type => record.material_type, :update_date => DateTime::now(), :isbn => record.isbn, :document_type_id => dt_id)
      notice.save!()
      return notice
    end
  end 
  
  def self.updateNoticeDCType(new_name, id_primary_dc_type)
    Notice.update_all("dc_type = '#{new_name.gsub(/'/, "\\\\'")}'", "document_type_id = #{id_primary_dc_type}")
  end
  
  # Method getNoticeByTagAndUser
  def self.getNoticesByTagAndUser(label,uuid) 
    Notice.find_by_sql ["select notices.doc_identifier, notices.doc_collection_id FROM notices, objects_tags, tags where tags.id = objects_tags.tag_id AND tags.label=#{label} AND objects_tags.object_type =1 AND  objects_tags.object_uid LIKE CONCAT(CONCAT(notices.doc_identifier,';'),notices.doc_collection_id) AND objects_tags.uuid=#{uuid}"]
  end
  
  # Method getNoticeByTagAndUser  
  def self.getOtherUsersNotices(label,uuid)
    Notice.find_by_sql ["select objects_tags.uuid, notices.doc_identifier, notices.doc_collection_id FROM notices, objects_tags, tags where tags.id = objects_tags.tag_id AND tags.label = '#{label}' AND objects_tags.object_type =1 AND  objects_tags.object_uid LIKE CONCAT(CONCAT(notices.doc_identifier,';'),notices.doc_collection_id) AND objects_tags.uuid NOT LIKE '#{uuid}' "]
  end
  
  def self.topByChamps(champs, page = 1, max=10)
    
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    
    req = "select SQL_CALC_FOUND_ROWS * "
    req += "from notices n, objects_counts o, collections c "
    req += "where o.object_type = #{ENUM_NOTICE} and o.object_uid = CONCAT(CONCAT(n.doc_identifier,','),n.doc_collection_id) and o.#{champs} > 0 "
    req += "and n.doc_collection_id = c.id "
    req += "order by o.#{champs} DESC "
    req += "limit #{offset}, #{max}"
    
    res = Notice.find_by_sql(req)
    total = 0
    count = Notice.find_by_sql("SELECT FOUND_ROWS() as total")
    if (!count.nil? and !count.empty?)
      total = count[0].total
    end
    
    tab = []
    res.each do |v|
      hash = Hash.new()
      v.attributes.each do |k, v|
        hash[k] = v
      end
      tab << hash
    end
    
    return {:result => tab, :count => total, :page => page, :max => max}
  end
end
