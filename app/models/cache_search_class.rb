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


class CacheSearchClass < ActionController::Base
  
  attr_reader :is_in_cache, :records, :records_id
  def initialize()
    @is_in_cache = is_in_cache
    @records = Array.new()
    @records = records
    @records_id = records_id
  end
  
  def SearchCollection(_objRec, _collect_id, _search_id, _max, job_id = -1, infos_user = nil, options=nil)
    _sTime = Time.now().to_f
    #======================================================
    # Check to see if data was cached -- if it is load
    #======================================================
    # NOTE: only runs for matched searches
    if _search_id != nil
      _lxml = CachedSearch.retrieve_metadata(_search_id, _collect_id, _max, infos_user)
      logger.debug("[cache_search_class][SearchCollection] object found in cache : #{_lxml.class}");
      if _lxml != nil
        @is_in_cache = true
        if _lxml.status == LIBRARYFIND_CACHE_OK
          # Note:  it should never happen that .data is nil
          if _lxml.data != nil
            # Load from cache
            @records =  _objRec.unpack_cache(_lxml.data, _max.to_i)
            if CACHE_ACTIVATE
              @records_id = "#{_search_id}_#{_collect_id}"
            else
              @records_id = _lxml.id
            end
          end
        else
          if _lxml.status == LIBRARYFIND_CACHE_ERROR
            @is_in_cache=false
          else
            @is_in_cache=true
            @records = nil
            if CACHE_ACTIVATE
              @records_id = "#{_search_id}_#{_collect_id}"
            else
              @records_id = _lxml.id
            end
          end
        end
      else
        @is_in_cache = false
        logger.debug("[cache_search_class][SearchCollection] object NOT found in cache")
      end
    end
    logger.debug("#STAT# [CACHE] base: [#{_collect_id}] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    return true
  end
  
  def self.GetRecord(idDoc = nil, idCollection = nil, idSearch = nil, infos_user = nil)
    
    logger.debug("GetRecord : idDoc:#{idDoc}, idCollection:#{idCollection}, idSearch:#{idSearch}")
    
    if idSearch == nil
      return nil
    end
    
    begin
      
      _lrecord = nil
      
      if CACHE_ACTIVATE
        cle = "#{idSearch}--#{idCollection}"
        _lrecord = CACHE.get(cle)
        if !_lrecord.blank?
          logger.info("[CacheSearchClass] [GetRecord] Data from cache with key: #{cle}")
        end
      end
      
      if (_lrecord.nil?)
        _objRec = RecordSet.new
        _lxml = CachedSearch.retrieve_metadata(idSearch.to_s, idCollection.to_s, -1, infos_user)
        if _lxml == nil
          return nil
        end
        _lrecord = _objRec.unpack_cache(_lxml.data, -1)
        
        
        if CACHE_ACTIVATE
          logger.info("[CacheSearchClass] [GetRecord] Set in cache with key = #{cle}")
          CACHE.set(cle, _lrecord, 3600.seconds)
        end
        
      end
      
      if _lrecord.nil?
        return nil
      end
      
      _lrecord.each do |rec|
        arr = rec.id.to_s.split(ID_SEPARATOR)
        if !arr.nil? and arr.length > 0 and arr[0] == idDoc.to_s
          return rec
        end 
      end
      logger.debug("No records matching")
    rescue => e
      logger.error("GetRecord can't retrieve informations : #{e.message}")
    end
    return nil
  end
  
end
