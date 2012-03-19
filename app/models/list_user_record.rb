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

class ListUserRecord < ActiveRecord::Base
  
  set_primary_keys :doc_identifier, :doc_collection_id, :uuid, :list_id
  
  belongs_to :list
  belongs_to :user_record, :foreign_key => [:doc_identifier, :doc_collection_id, :uuid]
  
  after_create { |list_user_record| 
    # increment notices_count for list
    ObjectsCount.incrementObjectsCount(ENUM_LIST, list_user_record.list_id, ENUM_NOTICE, 1)
    
    # increment lists_count for notice
    ObjectsCount.incrementObjectsCount(ENUM_NOTICE, "#{list_user_record.doc_identifier}#{ID_SEPARATOR}#{list_user_record.doc_collection_id}", ENUM_LIST, 1, list_user_record.list.state )
  }
  
  after_destroy { |list_user_record|
    # decrement notices_count for list
    ObjectsCount.decrementObjectsCount(ENUM_LIST, list_user_record.list_id, ENUM_NOTICE, 1)
    
    # decrement lists_count for notice
    ObjectsCount.decrementObjectsCount(ENUM_NOTICE, "#{list_user_record.doc_identifier}#{ID_SEPARATOR}#{list_user_record.doc_collection_id}", ENUM_LIST, 1, list_user_record.list.state)    
  }
  
  
  def self.existByUserRecordAndList?(user_record_id, list_id)
    logger.debug("[ListUserRecord] existByUserRecordAndList #{user_record_id},#{list_id}")
    return ListUserRecord.exists?("#{user_record_id},#{list_id}")
  end
  
  def self.upNoticeInList(list_id, user_record)
    record, col = user_record.split(",")
    up_rank = ListUserRecord.find(:first, :conditions => "list_id = '#{list_id}' AND '#{record}' = doc_identifier").rank  
    if up_rank == 1
      raise "cant't be up"
    end
    ListUserRecord.update_all('rank = rank + 1', "list_id = '#{list_id}' AND '#{up_rank - 1}' = rank")
    ListUserRecord.update_all('rank = rank - 1', "list_id = '#{list_id}' AND '#{record}' = doc_identifier")            
    return true
  end
  
  def self.downNoticeInList(list_id, user_record, max)
    record, col = user_record.split(",")
    down_rank = ListUserRecord.find(:first, :conditions => "list_id = '#{list_id}' AND '#{record}' = doc_identifier").rank
    #max = $objCommunityDispatch.getObjectCountById(3, list_id).notices_count
    if down_rank == max
      raise "can't be down"
    end
    ListUserRecord.update_all('rank = rank - 1', "list_id = '#{list_id}' AND '#{down_rank + 1}' = rank")
    ListUserRecord.update_all('rank = rank + 1', "list_id = '#{list_id}' AND '#{record}' = doc_identifier")            
    return true
  end
  
  def self.createListUserRecords(user_record_ids, list_id)
    list = List.find(list_id)
    
    if list.nil?
      raise "No List"
    end
    
    user_record_ids.each do |u|
      idDoc, idColl, uuid = u.split(",")
      if idDoc.nil? or idColl.nil? or uuid.nil?
        raise "Id bad #{u}"
      end
      if !ListUserRecord.exists?("#{u},#{list_id}")
        rank_list = (ListUserRecord.count_by_sql "SELECT COUNT(*) FROM list_user_records WHERE #{list_id} = list_id") + 1
        i = ListUserRecord.new()
        i.doc_identifier = idDoc
        i.doc_collection_id = idColl
        i.uuid = uuid
        i.list_id = list_id
        i.date_insert = DateTime::now()
        i.rank = rank_list
        i.save!
      end
    end
    
    return list
  end
  
  
  def self.deleteByListAndArrayId(list_id, uuid, list_user_records_array)
    rows = 0
    ListUserRecord.transaction do 
      list_user_records_array.each do |id|
        logger.debug("[ListUserRecord] deleteByListAndArrayId: #{id}")
        tmp = id.split(",")
        if !tmp.nil? and tmp.size == 4 and tmp[2] == uuid
          begin
            del_rank = ListUserRecord.find(:first, :conditions => "list_id = '#{list_id}' AND '#{tmp[0]}' = doc_identifier").rank
            ListUserRecord.update_all('rank = rank - 1', "list_id = '#{list_id}' AND '#{del_rank}' < rank")            
            ListUserRecord.destroy(tmp)
            rows += 1
          rescue => e
            logger.error("[ListUserRecord] deleteByListAndArrayId: #{e.message}")
            raise "Error with #{tmp}"
          end
        else
          logger.warn("[ListUserRecord] deleteByListAndArrayId: #{tmp} and #{uuid} are bad")
          raise "Bad Id #{tmp}"
        end
      end
    end
    return rows
  end
  
  def self.getRandomNotices(doc_id,max_notices)
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(doc_id)
    if doc_identifier.nil? or doc_collection_id.nil?
      raise "Id nil #{doc_id}"
    end
    list_user_records = ListUserRecord.find_by_sql("SELECT list_id FROM list_user_records WHERE doc_identifier = '#{doc_identifier}' and doc_collection_id = #{doc_collection_id} " )
    
    if(list_user_records.nil?)
      return {}
    end
    
    list_ids_tab = Array.new
    
    list_user_records.each do |l|
      list_ids_tab << l.list_id  
    end
    
    if list_ids_tab.nil? or list_ids_tab.empty?
      return {}
    else
      list_ids = list_ids_tab.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
    end
    
    notices_to_return = ListUserRecord.find_by_sql("SELECT DISTINCT(doc_identifier),doc_collection_id FROM list_user_records WHERE (doc_identifier != '#{doc_identifier}' or doc_collection_id != #{doc_collection_id}) and list_id IN #{list_ids} order by Rand() limit #{max_notices}")
    
    list_notices = Array.new
    
    notices_to_return.each do |ntr|
      list_notices << " (doc_identifier='#{ntr.doc_identifier}' and doc_collection_id=#{ntr.doc_collection_id}) "  
    end
    
    if list_notices.nil? or list_notices.empty?
      return {}
    else
      req = "SELECT * from notices WHERE #{list_notices.join("OR")}"
      logger.debug("requete:  #{req}")
      return Notice.find_by_sql(req)
    end
    
  end
  
end
