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

require 'rubygems'
require 'sru'

class SruSearchClass < ActionController::Base
  include SearchClassHelper
  attr_reader :hits, :xml
  @pkeyword = ""
  @feed_url = ""
  @feed_id = ""
  @search_id = ""
  @feed_type = "" 
  @feed_name = ""
  @total_hits = 0
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user=nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    _sTime = Time.now().to_f
    
    @records = []   
    @collection = _collect
    @pkeyword = _qstring.join(" ")
    @infos_user = infos_user
    @max = _max
    @action = _action_type
    @feed_url = _collect.vendor_url
    @feed_id = _collect.id
    @search_id = _last_id
    @feed_type = _collect.mat_type
    @feed_name = _collect.alt_name
    
    #====================================
    # Setup the OpenSearch Request
    #====================================    
    
    begin
      #initialize
      logger.debug("[SRU_SearchClass][searchCOllection] Start Initialize SRU::Client")
      logger.debug("[SRU_SearchClass][searchCOllection] Host: " + _collect.host)
      logger.debug("[SRU_SearchClass][searchCOllection] proxy : " + _collect.proxy.to_s)
      
      _params = _collect.zoom_params(_qtype[0])
      _params['search_id'] = _last_id
      _params['collection_id'] = _collect.id
      
      _options = {:recordSchema => _params['syntax'], :maximumRecords => _max, :parser => ::PARSER_TYPE}
      if (!_collect.user.blank? and !_collect.pass.blank?)
        _options[:username] = _collect.user.to_s
        _options[:password] = _collect.pass.to_s
      end
      if (_collect.proxy == 1)
        yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
        _host             = yp['PROXY_HTTP_ADR']
        _port             = yp['PROXY_HTTP_PORT']
        _options[:host]   = _host
        _options[:port]   = _port
      end
      logger.debug("[SRU_SearchClass][searchCOllection] inspect options : " + _options.inspect)
      client = SRU::Client.new(_collect.host.to_s, _options)
      logger.debug("[SRU_SearchClass][searchCOllection] Object SRU instantiate :-)")
      
      pquery = ""
      @pkeyword = @pkeyword.gsub("\"", "")
      if _qtype[0] == 'keyword'
        pquery = "anywhere=\"" + @pkeyword + "\""
      else
        pquery = _qtype[0] + "=" + "\"" + @pkeyword + "\""
      end 
      
      logger.debug("[SRU_SearchClass][searchCOllection]SRU Query: " + pquery)
      logger.debug("[SRU_SearchClass][searchCOllection]recordSchema: " + _params['syntax'])
      _sRTime = Time.now().to_f
      
      _options = {:recordSchema => _params['syntax'], :maximumRecords => _max, :parser => ::PARSER_TYPE}
      if (!_collect.user.blank? and !_collect.pass.blank?)
        _options[:username] = _collect.user.to_s
        _options[:password] = _collect.pass.to_s
      end
      if (_collect.proxy == 1)
        yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
        _host             = yp['PROXY_HTTP_ADR']
        _port             = yp['PROXY_HTTP_PORT']
        _options[:host]   = _host
        _options[:port]   = _port
      end
      
      sru_records = client.search_retrieve(pquery, _options)
      logger.debug("#STAT# [SRU] base: #{@feed_name}[#{@feed_id}] recherche: " + sprintf( "%.2f",(Time.now().to_f - _sRTime)).to_s) if LOG_STATS
      logger.debug("[SRU_SearchClass][searchCOllection]SRU Results: " + sru_records.entries.size.to_s)
      @total_hits = sru_records.entries.size
      _params['hits'] = sru_records.entries.size
      _objRec = RecordSet.new()
      _tmprec = nil
      for record in sru_records
        logger.debug("[SRU_SearchClass][searchCOllection]SRU -- have entered loop")
        logger.debug("[SRU Search Class][SearchCollection] record : " + record.inspect)
        #if marcxml then we unpack
        if _params['syntax'].downcase == 'marcxml'
          logger.debug("[SRU_SearchClass][searchCOllection]Processing SRU result" + record.inspect)
          record = record.to_s.gsub("</zs:recordData>", "").gsub("<zs:recordData>", "")
          _tmprec = _objRec.unpack_marcxml(_params, record, _params['def'], true, infos_user)
        else #assume dc
          _tmprec = _objRec.unpack_dc(_params, record, _params['def'])
        end
        
        _tmprec.vendor_name = _params['vendor_name']
        _tmprec.vendor_url  = _params['vendor_url']
        _tmprec.material_type = PrimaryDocumentType.getNameByDocumentType(_params['mat_type'], _collect.id)  
        if _tmprec.material_type.blank?
          _tmprec.material_type = UtilFormat.normalize(_collect.mat_type)
        end     
        _tmprec.actions_allowed = _collect.actions_allowed
        @records << _tmprec if _tmprec 
      end
    rescue => e
      logger.error("[SRU_SearchClass][searchCOllection] rescue 1 : " + e.message + "\n" + e.backtrace.join("\n"))
      raise e
    end    
    save_in_cache
  end
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user))
  end
end
