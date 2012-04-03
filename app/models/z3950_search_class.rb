#encoding:utf-8
# $Id: z3950_search_class.rb 386 2006-09-01 23:34:07Z dchud $

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

class Z3950SearchClass < ApplicationController
  @zoom = nil
  @total_hits = 0
  include SearchClassHelper
  
  def pFrenchNormalizeString(_qstring)
    if _qstring != nil
      x = 0
      y = _qstring.length
      y.times do
        _qstring[x] = _qstring[x].gsub("é", "e")
        _qstring[x] = _qstring[x].gsub("è", "e")
        _qstring[x] = _qstring[x].gsub("ù", "u")
        _qstring[x] = _qstring[x].gsub("ç", "c")
        _qstring[x] = _qstring[x].gsub("à", "a")
        _qstring[x] = _qstring[x].gsub("â", "a")
        _qstring[x] = _qstring[x].gsub("î", "i")
        _qstring[x] = _qstring[x].gsub("ê", "e")
        _qstring[x] = _qstring[x].gsub("ô", "o")
        _qstring[x] = _qstring[x].gsub("û", "u")         
        x = x + 1
      end
    end
    return _qstring
  end
  
  
  def SearchCollection(_coll, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user=nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    
    logger.debug("[Z3950] start search")
    _sTime = Time.now().to_f
    @search_id = _last_id
    @collection = _coll
    @pkeyword = _qstring.join(" ")
    @infos_user = infos_user
    @max = _max
    @action = _action_type
    @records = []
    _ltrecord = Array.new()
    _qstring = pFrenchNormalizeString(_qstring)
    _tmprec = nil
    record_set = RecordSet.new
    record_set.setKeyword( _qstring[0])
    
    #=======================================================
    # we put the require here so users don't
    # have to load the z39.50 components unless they have to
    #=======================================================
    #@zoom = RZOOM.new if @zoom.nil?
    _zoom = RZOOM.new #@zoom
    
    _params = _coll.zoom_params(_qtype[0])
    _params['search_id'] = @search_id
    _params['collection_id'] = @collection.id
    _params['definition_search'] = @collection.definition_search
    
    _sRTime = Time.now().to_f
    logger.debug("[Z3950SearchClass] [SearchCollection] param: #{_params.inspect} type: #{_qtype.inspect} string: #{_qstring.inspect} operator: #{_qoperator.inspect} start:#{_start} max:#{_max}")
    logger.debug("[Z3950SearchClass][SearchCollection] _coll = #{_coll.inspect}")
    _items = _zoom.search(_params, _qtype, _qstring, _qoperator, _start, @max.to_i)
    logger.debug("#STAT# [Z3950] base: #{_coll.name}[#{_coll.id}] recherche: " + sprintf( "%.2f",(Time.now().to_f - _sRTime)).to_s) if LOG_STATS
    
    @total_hits = _zoom.hits
    _params['hits'] = _zoom.hits
    
    if _items != nil 
      _startT = Time.now().to_f
      logger.debug("[Z3950SearchClass] [SearchCollection] schema : #{@collection.record_schema.downcase}")
      for _i in 0.._items.length-1
        case _coll.record_schema.downcase
          when "sutrs"
          rec = _objRec.sutrs2record(_items[_i].to_s, _params['def'], _params, _i)
          @records << rec if rec
        else
          logger.debug('Running here....')
          if _bool_obj == false
            rec = record_set.unpack_marcxml(_params, _items[_i].xml("marc8", "utf8"), _params['def'], false, @infos_user)
            rec.actions_allowed = @collection.actions_allowed
            _tmp << rec
          else
            _tmprec = record_set.unpack_marcxml(_params, _items[_i].xml("marc8", "utf8"), _params['def'], true, @infos_user)
            _tmprec.actions_allowed = @collection.actions_allowed
            @records << _tmprec if _tmprec
          end
        end 
      end  
      logger.info("[Z3950SearchClass] [SearchCollection] time create records object : #{Time.now().to_f - _startT} s")
      save_in_cache
    end
    
    logger.debug("#STAT# [Z3950] base: #{@collection.name}[#{@collection.id}] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    #end #End Thread
    #we return a nil because the data is stored in the thread variables.
    #return nil  
    if @action 
      logger.debug("action_type set")
      if @records 
        return @my_id, @records.length, @total_hits
      else
        return @my_id, 0, @total_hits
      end
    else
      logger.debug("action_type not set")
      return @records
    end
  end
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch,infos_user));
  end
end
