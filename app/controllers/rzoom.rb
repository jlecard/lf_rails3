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


class RZOOM   < ActionController::Base
  require 'zoom'
  require 'timeout'
  
  @info = false
  attr_reader :hits
  
  def definition_sarch_to_hash(definition_search)
    definition_search_hash = {}
    if !definition_search.blank?
      tab = definition_search.split(";")
      tab.each do |elt|
        v = elt.split("=")
        logger.debug("definition_search_hash : #{v.inspect}")
        if (!v.nil? and !v.empty?) 
          if (v.size == 2)
            definition_search_hash[v[0]] = "#{v[1]}"
          else
            definition_search_hash[v[0]] = ""
          end
        end
      end
    else
      definition_search_hash = {"creator" => "1003", "author" => "1003", "subject" => "21", "issn" => "8", "isbn" => "7", "callnum" => "16", "publisher" => "1018", "title" => "4", "keyword" => "1016"}  
    end
    return definition_search_hash
  end
  
  
  def getType(hash_bib, type)
    begin
      tmp = hash_bib[type]
      if !tmp.blank?
        return tmp
      end
    rescue
    end
    raise ArgumentError, "TYPE_INCONNU", caller 
  end
  
  def bib_query (definition_search, type, chaine, operateur)
    i = 0
    requette = ""
    #    hash_bib 
    hash_bib = definition_sarch_to_hash(definition_search)
    while i < chaine.length
      taille = i - 1
      if i == 0
        taille = i - 1
        requette = "@attr 1=#{getType(hash_bib,type[i])} \"#{chaine[i]}\" #{requette}"
        i = i + 1
      end
      if taille >=0
        if (((i > 0) && (!operateur[taille].nil?)) && (!operateur[taille].downcase.eql?("not")))
          taille = i - 1
          requette = "@#{operateur[taille].downcase} @attr 1=#{getType(hash_bib,type[i])} \"#{chaine[i]}\" #{requette}"
          i = i + 1
        elsif ((!operateur[taille].nil?) && (operateur[taille].downcase.eql?("not")))
          taille = i - 1
          requette = "@#{operateur[taille].downcase} #{requette} @attr 1=#{getType(hash_bib,type[i])} \"#{chaine[i]}\""
          i = i + 1
        else
          break
        end
      end
    end
    return requette
  end
  
  def search(_host, _stype, _keyword, _operator, _start=0, _max=10) 
    _startTop = Time.now().to_f
    logger.info("[rzoom][search] Username: #{_host['username']}")
    logger.info("[rzoom][search] Password:#{_host['password']}")
    logger.info("[rzoom][search] Database Name: " + _host['name'])
    logger.info("[rzoom][search] Host: " + _host['host']) 
    logger.info("[rzoom][search] Port: " + _host['port'].to_s)
    logger.info("[rzoom][search] Syntax: " + _host['syntax'])
    logger.info("[rzoom][search] _stype : " + _stype.inspect)
    logger.info("[rzoom][search] _keyword : " + _keyword.inspect)
    logger.info("[rzoom][search] _operator : " + _operator.inspect)
    logger.info("[rzoom][search] proxy : " + _host['proxy'].inspect)
    _records = Array.new
    if _max.class!="Int"
      _max = _max.to_i end
    begin 
      hOptions = Hash.new
      if (_host['username']!="")
        hOptions['user'] = _host['username']
      end
      
      if (_host['password']!='')
        hOptions['password'] = _host['password']
      end 
      
      if (_host['proxy'] == 1)
        yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml");
        _proxyHost = yp['PROXY_HTTP_ADR'];
        _proxyPort = yp['PROXY_HTTP_PORT'];
        logger.debug("[rzoom][search] use proxy with #{_proxyHost} and #{_proxyPort}")
        hOptions['proxy'] = "#{_proxyHost}:#{_proxyPort}"
      end
      logger.info("[rzoom][search] Create connection with options : #{hOptions.inspect}")
      _startCnx = Time.now().to_f
      #conn = ZOOM::Connection.new(hOptions) 
      conn = ZOOM::Connection.new
      conn.user = hOptions['user']
      conn.password = hOptions['password']
      conn.proxy = hOptions['proxy']
      logger.debug("[rzoom][search] time prepare connection : #{Time.now().to_f - _startCnx} s")
      
      if conn != nil
        is_connected=true
        logger.debug("[rzoom][search] connect with host: #{_host['host']} port:#{_host['port']}")
        _startCnx = Time.now().to_f
        conn = conn.connect(_host['host'].to_s, _host['port'].to_i)
        logger.debug("[rzoom][search] time connection : #{Time.now().to_f - _startCnx} s")
        conn.set_option('timeout', LIBRARYFIND_PROCESS_TIMEOUT)
        conn.set_option("elementSetName","F")
        conn.database_name = _host['name'] 
        conn.preferred_record_syntax = _host['syntax']
        _querystring = bib_query(_host['definition_search'], _stype, _keyword, _operator)
        logger.info("[rzoom][search] _querystring : #{_querystring}")
        rset = ZOOM::ResultSet
        logger.debug("[rzoom][search] requete : #{_querystring} time start")
        _startT = Time.now().to_f
        rset = conn.search(_querystring)
        logger.info("[rzoom][search] time request : #{Time.now().to_f - _startT} ms")
        logger.debug("[rzoom][search] result size : #{rset.size}")
        
        if  _host['isword'].to_i > 0
          if rset.size == 0 
            if _querystring.index("@attr 1=4")!=nil && _querystring.index("@attr 1=1016")!=nil
              logger.info("[rzoom][search] new search: " + _querystring.slice(_querystring.index("@attr 1=1016"), (_querystring.length-_querystring.index("@attr 1=1016"))))
              rset = conn.search(_querystring.slice(_querystring.index("@attr 1=1016"), (_querystring.length-_querystring.index("@attr 1=1016"))))
            end
          end
        end
        @hits = rset.size
        logger.debug("[rzoom][search] Max Hits: #{@hits}")
        if rset.size >= _max
          _hits = _max
        else 
          _hits = rset.size
        end
        logger.debug("[rzoom][search] hits: " + _hits.to_s)
        logger.info("[rzoom][search] set_option timeout: #{LIBRARYFIND_PROCESS_TIMEOUT}")
        #rset.set_option('timeout', LIBRARYFIND_PROCESS_TIMEOUT)
        begin
          status = Timeout::timeout(LIBRARYFIND_PROCESS_TIMEOUT*2) {
            logger.info("[rzoom][search] in TimeOut fonction ")
            
            logger.debug("[rzoom][search] Before BIB : " + _host['bib_attr'].inspect)
            if ((!_host['bib_attr'].nil?) && 
             (!_host['bib_attr'].index('@').nil?))
              _startT = Time.now().to_f
              logger.debug("[rzoom][search] Have bib : ")
              rset.set_option('elementSetName', 'F')
              logger.debug("[rzoom][search] time set bib attributes : #{Time.now().to_f - _startT} s")
            end
            
            if _start < 1
              _start = 0 
            end
            _startT = Time.now().to_f
            _records = rset[_start, _hits]
            logger.info("[rzoom][search] time get records : #{Time.now().to_f - _startT} s")
            logger.debug("[rzoom][search] records : #{_records.size}")
          }
          logger.info("[rzoom][search] status : #{status}")
        rescue Timeout::Error => te
          logger.error("[rzoom][search] Timeout error")
          raise te
          return nil
        rescue => er
          logger.error("[rzoom][search] other error :" + er.message)
          raise er
          return nil
        end
      end
      logger.info("[rzoom][search] # Time total method #: #{Time.now().to_f - _startTop} s")
      if is_connected==false
        logger.debug('[rzoom][search] Not Connected')
        return nil
      else
        return _records
      end
    rescue StandardError => bang
      logger.error("[rzoom][search] Error: " + bang.message + bang.backtrace.join("\n"))
      raise bang
      return nil
    rescue => e
      logger.error("[rzoom][search] Raise Error:" + e.message)
      raise e
      return nil #_records
    end
  end
  
  def normalize(_string)
    return "" if _string == nil
    if _string.class!="String" then _string = _string.to_s end
    _string = _string.gsub(/&/,'and')
    #_string = _string.gsub(/'/,'')
    _string = _string.gsub('"',"'")
    #_string = '"' + _string + '"'
    return _string
  end
  
  
  
end
