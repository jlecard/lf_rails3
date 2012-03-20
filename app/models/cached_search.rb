# $Id: cached_search.rb 1281 2008-12-18 03:13:50Z reeset $

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

# Use to be cached_searches.  Moved to 
# accom. rails naming convention

require 'yajl'

class InCacheRecord
  attr_accessor :max, :data, :search_id, :collection_id, :search_time, :status, :total_hits, :id_perm, :id_role, :id_lieu
  
  def initialize(metadata, max, coll_id, status, total_hits,id_perm = nil, id_role = nil, id_lieu = nil )
    @data = metadata    
    @max = max
    @collection_id = coll_id
    @status = status
    @total_hits = total_hits
    @id_perm = id_perm
    @id_role = id_role
    @id_lieu = id_lieu
  end
  
end

class CachedSearch < ActiveRecord::Base
  has_many :hit
  has_many :cached_record
  
  def self.check_cache(query, type, set, max, infos_user, operator=[])
    
    query_string = ""
    type_string = ""
    if query != nil && query.length() > 1
      x = 0
      y = query.length - 1
      y.times do
        query[x] = query[x].gsub("'", "")
        x = x + 1
      end 
      query_string = query.join('|LF_DEL|') #to_like_conditions(query)
      type_string = type.join('|LF_DEL|') #to_like_conditions(type)
      operator_string = operator.join('|LF_DEL|') #to_like_conditions(operator)
    else
      if query != nil && query.length() > 0
        query_string = query[0].gsub("'", "")
        type_string = type[0]
        operator_string = operator[0]
      end
    end
    
    if CACHE_ACTIVATE
      if infos_user and !infos_user.location_user.blank?
        key = Digest::SHA1.hexdigest("#{query_string}#{type_string}#{set}#{max}#{infos_user.location_user}")
      else
        key = Digest::SHA1.hexdigest("#{query_string}#{type_string}#{set}#{max}")
      end
      logger.info("[cached_search][check_cache] GETTING QUERY KEY #{key}")
      retval = CACHE.get(key)
      logger.debug("[cached_search][check_cache] GETTING QUERY KEY #{key}=#{retval}")
      return nil if retval.nil?
      return key, retval
    end
    
    #TODO: Ajouter l'operator dans la base de donnee
    
    objRecords = CachedSearch.find(:all, :conditions => "query_string='#{query_string}'  AND query_type='#{type_string}'")
    return nil if objRecords == nil
    return objRecords
    
    
  end
  
  
  def self.set_query (query, type, set, max, infos_user)
    require "date"
    
    query_string = ""
    type_string = ""
    if query != nil && query.length() > 1 
      x = 0
      y = query.length() -1
      y.times do
        query[x] = query[x].gsub("'", "")
        x = x + 1
      end 
      query_string = query.join("|LF_DEF|")
      type_string = type.join("|LF_DEF|")
    else
      if query != nil && query.length() > 0
        query_string = query[0].gsub("'", "")
        type_string = type[0]
      end
    end
    
    if CACHE_ACTIVATE
      if infos_user and !infos_user.location_user.blank?
        key = Digest::SHA1.hexdigest("#{query_string}#{type_string}#{set}#{max}#{infos_user.location_user}")
      else
        key = Digest::SHA1.hexdigest("#{query_string}#{type_string}#{set}#{max}")
      end
      val = max
      logger.info("[cached_search][set_query] setting query object key = #{key}")
      CACHE.set(key, val, 3600.seconds)
      return key, max
    end

    objSearch = CachedSearch.new("query_string" => query_string, "query_type" => type_string, "collection_set" => set, "created_at" => Time.now, "max_recs" =>max)
    objSearch.save
    return objSearch.id
  end
  
  
  def self.update_query(id, max)
    objSearch = CachedSearch.find(id, :lock=>true)
    objSearch.max_recs = max
    objSearch.save
  end
  
  # infos_user added to control access to cache
  def self.retrieve_metadata(sid, coll_id, max, infos_user = nil)
    _sTime = Time.now().to_f

    if CACHE_ACTIVATE
      if infos_user and !infos_user.location_user.blank?
        obj = CACHE.get("#{sid}_#{coll_id}_#{infos_user.location_user}")
        logger.debug("[cached_search][retrieve_metadata]: return object class = #{obj.class} for key #{sid}_#{coll_id}_#{infos_user.location_user}")
      else
        obj = CACHE.get("#{sid}_#{coll_id}")
        logger.debug("[cached_search][retrieve_metadata]: return object class = #{obj.class} for key #{sid}_#{coll_id}")
      end
      logger.debug("[cached_search][retrieve_metadata]:  object : #{obj.inspect}")
      return obj
    end
    objRecords = CachedRecord.find(:all, :conditions => "search_id='#{sid}' AND collection_id=#{coll_id} ", :order => "created_at DESC")      

    
    return nil if objRecords[0] == nil
    if max > -1
      return nil if objRecords[0].max_recs < max
    end
    logger.debug("#STAT# [CACHESEARCH] base: [#{coll_id}] recherche: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    return objRecords[0]
  end 
  
  # saving infos_user with cached_records
  def self.save_metadata(sid, metadata, coll_id, max, istatus, infos_user=nil, total_hits=0)
    
    if CACHE_ACTIVATE
      if (INFOS_USER_CONTROL and !infos_user.nil?)
        droits = ManageDroit.GetDroits(infos_user,coll_id)
        cache = InCacheRecord.new(metadata, max, coll_id, istatus.to_i, total_hits, droits.id_perm, droits.id_role, droits.id_lieu )
      else
        cache = InCacheRecord.new(metadata, max, coll_id, istatus.to_i, total_hits)
      end
      # object = Yajl::Encoder.encode(cache)
      if infos_user and !infos_user.location_user.blank?
        key = "#{sid}_#{coll_id}_#{infos_user.location_user}"
      else
        key = "#{sid}_#{coll_id}"
      end
      CACHE.set(key, cache, 3600.seconds)
      logger.debug("[cached_search][save_metadata] setting object of key = #{key}")
      return key
    end
    
    objTest = CachedRecord.find(:all, :conditions => "search_id='#{sid}' AND collection_id=#{coll_id} ", :lock=>true)
    if objTest[0]==nil
      if(INFOS_USER_CONTROL and !infos_user.nil?)
        droits = ManageDroit.GetDroits(infos_user,coll_id)
        objRecords = CachedRecord.new("search_id" => sid, "data" => metadata, "collection_id" => coll_id, "max_recs" => max, "status"=> istatus.to_i, "total_hits" => total_hits, "id_perm" => droits.id_perm, "id_role" => droits.id_role, "id_lieu" => droits.id_lieu)
      else
        objRecords = CachedRecord.new("search_id" => sid, "data" => metadata, "collection_id" => coll_id, "max_recs" => max, "status"=> istatus.to_i, "total_hits" => total_hits)
      end
      objRecords.save
      return objRecords.id
    else 
      objTest[0].data = metadata
      objTest[0].max_recs = max
      objTest[0].status = istatus.to_i
      objTest[0].save 
      return objTest[0].id
    end
    
  end
  
  def self.save_execution_time(sid, coll_id, stime, infos_user)
    if CACHE_ACTIVATE
      begin
        if infos_user and !infos_user.location_user.blank?
          key = "#{sid}_#{coll_id}_#{infos_user.location_user}"
          obj = CACHE.get(key)
        else
          key = "#{sid}_#{coll_id}"
          obj = CACHE.get(key)
        end
        
        logger.info("[cached_search][save_execution_time] found object key #{key} : #{obj.class}")
        if !obj.nil? && obj.instance_of?(InCacheRecord)
          obj.search_time = stime 
          #CACHE.set("#{sid}_#{coll_id}",Yajl::Encoder.encode(robject), 3600.seconds)

          CACHE.set(key,obj, 3600.seconds)
          logger.info("[cached_search][save_execution_time] setting object of key #{key}")
          logger.info("[cached_search][save_execution_time] setting object of class #{obj.class}")
        else
          logger.info("[cached_search][save_execution_time] did not find object of key #{sid}_#{coll_id}")
        end
        return key
      rescue Exception  => e
        logger.error("[cached_search] [save_execution_time] error getting or setting cache key #{sid}_#{coll_id}")
        logger.error("[cached_search] [save_execution_time] error #{e.message}")
        logger.debug("[cached_search] [save_execution_time] error #{e.backtrace}")
      end
    end
    objTest = CachedRecord.find(:all, :conditions => "search_id='#{sid}' AND collection_id='#{coll_id}'", :lock=>true)
    if objTest[0]!=nil
      objTest[0].search_time = stime
      objTest[0].save
    end 
  end
  
  def self.save_hits(sid, session_id, result_count, action_type, data) 
    objHits = Hit.new("session_id" => session_id, "search_id" => sid, "result_count" => result_count, "action_type" => action_type, "data" => data)
    objHits.save
  end
  
  
  def self.get_item(sid) 
    arr = sid.split(";")
    if CACHE_ACTIVATE
      objRecords = CACHE.get("#{arr[0]}_#{arr[1]}")
      return objRecords unless objRecords.nil?
      return nil
    end
    
    objRecords = CachedRecord.find(:all, :conditions => "search_id='#{arr[0]}' AND collection_id='#{arr[1]}'")
    return nil if objRecords[0] == nil
  end
  
  def self.build_cache_xml(lrecords) 
    return Yajl::Encoder.encode(lrecords)
  end
  
  def self.to_like_conditions( conditions )
    like_conditions = []
    key_count = conditions.size
    k = ""
    conditions.each_key do |key|
      k += "#{key} LIKE ?"
      if key_count > 1 
        k += " and "
      end
      key_count -= 1
    end
    like_conditions << k
    
    conditions.each_value do |value| 
      like_conditions << "%#{value}%"
    end
    
    return like_conditions
  end
end
