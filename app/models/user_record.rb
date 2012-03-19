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

class UserRecord < ActiveRecord::Base
  
  set_primary_keys :doc_identifier, :doc_collection_id, :uuid
  
  belongs_to :notice, :foreign_key => [:doc_identifier, :doc_collection_id]
  
  has_many :list_user_records, :foreign_key => [:doc_identifier, :doc_collection_id, :uuid], :dependent => :destroy
  
  has_many :lists, :through => :list_user_records, :foreign_key => [:doc_identifier, :doc_collection_id, :uuid]
  
  after_create { |user_record|
    state = 1
    # Increment notices_count/notices_count_public for user
    ObjectsCount.incrementObjectsCount(ENUM_COMMUNITY_USER, user_record.uuid, ENUM_NOTICE, 1, state)
  }
  
  after_destroy { |user_record|  
    state = 1
    # Decrement notices_count/notices_count_public for user
    ObjectsCount.decrementObjectsCount(ENUM_COMMUNITY_USER, user_record.uuid, ENUM_NOTICE, 1, state)
  }
  
  def self.addUserRecord(idDocument, idCollection, idUser)
    logger.debug("[UserRecord] addUserRecord = #{idDocument},#{idCollection},#{idUser}")
    if !UserRecord.exists?("#{idDocument},#{idCollection},#{idUser}")
      userRecord = UserRecord.new("doc_identifier" => idDocument, "doc_collection_id" => idCollection, "uuid" => idUser, "date_insert" => DateTime::now())
      userRecord.save!()
      return userRecord
    else
      logger.debug("[UserRecord] addUserRecord = already exist")
      return nil
    end
  end
  
  def self.existById?(doc, user)
    idDoc, idColl, idSearch = UtilFormat.parseIdDoc(doc)
    return UserRecord.exists?("#{idDoc},#{idColl},#{user}")
  end
  
  def self.deleteUserRecordsByUser(userRecordArray, uuid)
    
    logger.debug("[UserRecord] deleteUserRecordByUser = #{userRecordArray} uuid = #{uuid} class = #{userRecordArray.class}")
    rows = 0
    UserRecord.transaction do 
      userRecordArray.each do |id|
        logger.debug("[UserRecord] delete: #{id}")
        tmp = id.split(",")
        if !tmp.nil? and tmp.size == 3 and tmp[2] == uuid
          UserRecord.destroy(tmp)
          rows += 1
        else
          logger.warn("[UserRecord] deleteUserRecordByUsers : #{tmp} and #{uuid} are bad")
          raise "Bad Id #{tmp}"
        end
      end
    end
    return rows
  end
  
  def self.getUserRecordsByUser(uuid, max, page, sort, direction)
    offset = (page - 1) * max
    
    if SORT_TYPE == sort
      c_sort = "n.dc_type"
    elsif SORT_AUTHOR == sort
      c_sort = "n.dc_author"
    elsif SORT_TITLE == sort
      c_sort = "n.dc_title"
    elsif SORT_DATE == sort
      c_sort = "u.date_insert"
    else
      c_sort = "n.dc_type"
    end
    
    if DIRECTION_UP == direction
      c_direction = "ASC"
    elsif DIRECTION_DOWN == direction
      c_direction = "DESC"
    else
      c_direction = "ASC"
    end
    
    requete = "select u.uuid, u.doc_identifier, u.doc_collection_id, DATE_FORMAT(u.date_insert,'%d/%m/%Y') as date, n.dc_type, n.dc_title, n.dc_author"
    requete += " from notices n, user_records u where u.doc_identifier = n.doc_identifier and u.doc_collection_id = n.doc_collection_id and u.uuid = '#{uuid}'"
    requete += " ORDER BY #{c_sort} #{c_direction} LIMIT #{offset}, #{max}"
    
    # SELECT n.doc_identifier, l.title FROM notices n, user_records u  LEFT OUTER JOIN list_user_records lur JOIN lists l ON (lur.list_id = l.id) ON (lur.doc_identifier = u.doc_identifier AND lur.doc_collection_id = u.doc_collection_id AND lur.uuid = u.uuid)  WHERE u.doc_identifier = n.doc_identifier  AND u.doc_collection_id = n.doc_collection_id  AND u.uuid = 'gee' ORDER BY n.dc_type ASC  LIMIT 0, 10;
    logger.debug("requete => #{requete}")
    return UserRecord.find_by_sql(requete)
    
  end
end
