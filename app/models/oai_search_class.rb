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

class OaiSearchClass < ActionController::Base
  include SearchClassHelper
  
  attr_reader :hits, :xml
  
  @total_hits = 0
  @pid = 0
  @pkeyword = ""
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator,_last_id, job_id = -1, infos_user=nil, options=nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    
    logger.debug("[OAI] start search")
    _sTime = Time.now().to_f
    
    @records = []
    keyword(_qstring[0])
    @collection = _collect
    @search_id = _last_id
    @infos_user = infos_user
    @max = _max
    @action = _action_type
    
    # _query = "SELECT DISTINCT CN.id, CN.alt_name, C.id, C.oai_identifier, C.collection_id, C.url, C.title, C.description, M.dc_subject, M.dc_creator, M.dc_date, M.dc_format, M.dc_type, M.osu_thumbnail, M.dc_language, M.dc_relation, M.dc_coverage, M.dc_rights,M.dc_source, M.dc_publisher,M.dc_contributor, M.osu_volume from collections CN LEFT JOIN controls C ON CN.id=C.collection_id  LEFT JOIN metadatas M on C.id = M.controls_id where ("
    _query = "SELECT DISTINCT CN.id, CN.alt_name, C.id, CN.vendor_url,
               C.oai_identifier as oai_identifier, C.collection_id as collection_id, C.url, C.title, C.description, 
               M.dc_subject as dc_subject, M.dc_creator as dc_creator, M.dc_date as dc_date, 
               M.dc_format as dc_format, M.dc_type as dc_type, M.osu_thumbnail as osu_thumbnail, M.dc_language as dc_language, 
               M.dc_relation as dc_relation, M.dc_coverage as dc_coverage, M.dc_rights as dc_rights,
               M.dc_source as dc_source, M.dc_publisher as dc_publisher, M.dc_contributor as dc_contributor, 
               M.osu_volume as osu_volume 
               FROM collections CN LEFT JOIN controls C ON CN.id=C.collection_id 
               LEFT JOIN metadatas M on C.id = M.controls_id where ("
    _coll_list =_collect.id 
    _type = _collect.mat_type
    _alias = _collect.alt_name
    _group = _collect.virtual
    _is_parent = _collect.is_parent
    _col_name = _collect.name
    _vendor_url = _collect.vendor_url
    _availability = _collect.availability
    
    @records = RetrieveOAI_Single(_last_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url, _is_parent, _col_name,_max.to_i, _collect.filter_query, infos_user, options, _availability)
    
    save_in_cache
  end
  
  def self.RetrieveOAI_Single(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name,  _max, filter_query, infos_user=nil, options=nil, _availability=nil)
    htype = {_coll_list => _type}
    halias = {_coll_list => _alias}
    hgroup = {_coll_list => _group}
    hvendor = {_coll_list => _vendor_url}
    hparent = {_coll_list => _is_parent}
    hcolname = {_coll_list => _collection_name}
    logger.debug("Oai_Qstring2: " + _qstring.length.to_s)
    return  RetrieveOAI(_search_id, _query, _qtype, _qstring, _qoperator, htype, _coll_list, halias, hgroup, hvendor, hparent, hcolname, _max, filter_query, infos_user, options, _availability)
  end
  
  def self.RetrieveOAI(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name, _max, filter_query, infos_user=nil, options=nil, _availability=nil)
    _x = 0
    _oldset = ""
    _newset = ""
    _count = 0
    _tmp_max = 1
    _start_time = Time.now()
    _objRec = RecordSet.new()
    _hits = Hash.new()
    _dateIndexed = Hash.new()
    _bfound = false;
    
    logger.debug("OAI Search")
    
    _max = _max.to_i
    
    _keywords = _qstring.join("|")
    #if _keywords.slice(0,1)=='"'
    #_keywords = _keywords.gsub(/^"*/,'')
    #_keywords = _keywords.gsub(/"*$/,'')
    #logger.debug("keywords exit")
    #else  
    #   _keywords = '"' + _keywords + '"' 
    #end 
    
    _site = nil 
    _sitepref = nil 
    logger.debug("[OaiSearchClass][RetrieveOAI] KEYWORD BEFORE PREF: " + _keywords)
    
    if _keywords.index("site:")!= nil 
      _site = _keywords.slice(_keywords.index("site:"), _keywords.length - _keywords.index("site:")).gsub("site:", "")
      _keywords = _keywords.slice(0, _keywords.index("site:")).chop
      if _site.index('"') != nil
        _site = _site.gsub('"', "")
        _keywords << '"'
      end
    elsif _keywords.index("sitepref:") != nil
      _sitepref = _keywords.slice(_keywords.index("sitepref:"), _keywords.length - _keywords.index("sitepref:")).gsub("sitepref:", "")
      logger.debug("[OaiSearchClass][RetrieveOAI] SITE PREF: " + _sitepref)
      _keywords = _keywords.slice(0, _keywords.index("sitepref:")).chop
      if _sitepref.index('"') != nil
        _sitepref = _sitepref.gsub('"', "")
        _keywords << '"'
      end
    end
    logger.debug("[OaiSearchClass][RetrieveOAI] KEYWORDs: " + _keywords)
    _calc_keyword = _keywords
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      _keywords = UtilFormat.normalizeFerretKeyword(_keywords)
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      _keywords = UtilFormat.normalizeSolrKeyword(_keywords)
    end
    
    if _keywords.slice(0,1) != "\""
      if _keywords.index(' OR ') == nil
        _keywords = _keywords.gsub("\"", "'")
        #I think this is a problem.
        #_keywords = "\"" + _keywords + "\""
      end
    end
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      
      #_keywords = _keywords.gsub("'", "\'")   
      #_keywords = _keywords.gsub("\"", "'")
      #index = Ferret::Index::Index.new(:path => LIBRARYFIND_FERRET_PATH)
      #  index.search_each('collection_id:(' + _coll_list.to_s + ') AND ' + _qtype.join("|") + ':"' + _keywords + '"', :limit => _max) do |doc, score|
      index = Ferret::Search::Searcher.new(LIBRARYFIND_FERRET_PATH)
      #index = Ferret::Index::Index.new(:path => LIBRARYFIND_FERRET_PATH)
      queryparser = Ferret::QueryParser.new()
      logger.debug("[OaiSearchClass][RetrieveOAI] KEYWORD: " + _keywords)
      if _is_parent[_coll_list] == 1 
        logger.debug("[OaiSearchClass][RetrieveOAI] IS PARENT")
        raw_query_string = 'collection_id:("' + UtilFormat.normalizeFerretKeyword(_coll_list.to_s) + '") AND ' + _qtype.join("|") + ":(" + _keywords + ")"
        query_object = queryparser.parse(raw_query_string)
        logger.debug("RAW FERRET QUERY: "  + raw_query_string)
        logger.debug("FERRET QUERY: " + query_object.to_s)
      else
        logger.debug("[OaiSearchClass][RetrieveOAI]  NOT PARENT: " + _collection_name[_coll_list])
        _collection_name[_coll_list] = _collection_name[_coll_list].gsub("http_//", "") 
        
        raw_query_string = "collection_name:(\"" + UtilFormat.normalizeFerretKeyword(_collection_name[_coll_list]) + "\") AND " + _qtype.join("|") + ":(" + _keywords + ")"
        query_object  = queryparser.parse(raw_query_string)
        logger.debug("[OaiSearchClass][RetrieveOAI] RAW FERRET QUERY: " + raw_query_string)
        logger.debug("[OaiSearchClass][RetrieveOAI] FERRET QUERY: " + query_object.to_s)
      end
      index.search_each(query_object, :limit => _max) do |doc, score|
        
        # An item should have a score of 50% or better to get into this list
        break if score < 0.40
        _query << " controls.id='" + index[doc]["controls_id"].to_s + "' or "
        _bfound = true;
        
      end 
      
      index.close
      
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      
      logger.debug("Entering SOLR")
      conn = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
      raw_query_string, opt = UtilFormat.generateRequestSolr(_qtype, _qstring, _qoperator, filter_query, _is_parent[_coll_list], _coll_list, _collection_name[_coll_list], _max, options)
      
    end
    
    
    logger.info("[OAI_SEARCH_CLASS] requete solr: " + raw_query_string)
    _response = conn.query(raw_query_string, opt)
    @total_hits = _response.total_hits
    
    _response.each do |hit|
      if defined?(hit["controls_id"]) == false
        break
      end 
      _query << " C.id='" + hit["controls_id"].to_s + "' or "
      _dateIndexed[hit["controls_id"].to_s] = hit["harvesting_date"]
      _bfound = true
    end
    
    
    if _bfound == false 
      logger.debug("nothing found: " + _coll_list.to_s)
      return nil 
    end
    _query = _query.slice(0, (_query.length- " or ".length)) + ")"
    
    if _site != nil 
      _query << " and C.url like '%" + _site + "%'"
    end
    _query <<  " and C.collection_id=#{_coll_list} order by C.collection_id"
    
    
    logger.debug("[OaiSearchClass][RetrieveOAI] COLLECION: " + _coll_list.to_s + " -- QUERY: " + _query)
    
    _sTime = Time.now().to_f
    _results = Collection.find_by_sql(_query) 
    logger.debug("#STAT# [OAI] base: [#{_coll_list}] recherche: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
    _record = Array.new()
    _i = 0
    _newset = ""
    _trow = nil
    collection = Collection.find(_coll_list)
    _results.each { |_row|
      if _is_parent[_coll_list] != 1
        logger.debug("Find: " + _coll_list.to_s)
        _trow = Collection.find(_coll_list)
        if _trow != nil then  
          logger.debug("[OaiSearchClass][RetrieveOAI] COLLECTION RESOLVED")
          _newset = _trow.alt_name
          logger.debug('[OaiSearchClass][RetrieveOAI] NEW COLLECTION NAME SET' + _newset)
        else
          logger.debug("[OaiSearchClass][RetrieveOAI] CHECK: " +  _row.collection_id.to_s + ";" + UtilFormat.normalize(_row.oai_identifier))
          _newset = _row.alt_name
        end
      else
        logger.debug("[OaiSearchClass][RetrieveOAI] CHECK: " +  _row.collection_id.to_s + ";" + UtilFormat.normalize(_row.oai_identifier))
        _newset = _row.alt_name
      end
      
      if _oldset != ""  
        if  _oldset != _newset
          _hits[_oldset] = _tmp_max-2 
          _count = 0
          _tmp_max = 1
        end
      elsif _oldset == ""
        #_alias[_row["collection_id"]] = ""
        _count = 0
      end
      
      if _tmp_max <= _max
        logger.debug("[OaiSearchClass][RetrieveOAI] Prepping to print Title, etc.")
        record = Record.new()
        logger.debug("[OaiSearchClass][RetrieveOAI] Title: " + UtilFormat.normalize(_row['title']))
        logger.debug("[OaiSearchClass][RetrieveOAI] creator: " + UtilFormat.normalize(_row.dc_creator))
        logger.debug("[OaiSearchClass][RetrieveOAI] date: " + UtilFormat.normalizeDate(_row.dc_date))
        logger.debug("[OaiSearchClass][RetrieveOAI] description: " + UtilFormat.normalize(_row.description))
        logger.debug("[OaiSearchClass][RetrieveOAI] SITE PREF: " + UtilFormat.normalize(_sitepref))
        logger.debug("[OaiSearchClass][RetrieveOAI] SITE URL: " + UtilFormat.normalize(_row.url))
        
        harvesting_date = _dateIndexed[_row['dc_identifier'].to_s]
        if (!harvesting_date.nil?)
          harvesting_date = DateTime.parse(harvesting_date)
        else
          harvesting_date = ""
        end
        record.date_indexed = harvesting_date
        
        begin
          record.rank = _objRec.calc_rank({'title'   => UtilFormat.normalize(_row.title), 
                                            'atitle'  => '',
                                            'theme'   => '', # UtilFormat.normalize(_row.theme),
                                            'creator' =>UtilFormat.normalize(_row.dc_creator), 
                                            'date'    => _row.dc_date,
                                            'rec'     => UtilFormat.normalize(_row.description),
                                            'pos'     =>1,
                                            'pref'    => _sitepref,
                                            'url'     => UtilFormat.normalize(_row.url) },
          _calc_keyword)
        rescue StandardError => bang2 
          logger.debug("ERROR: " + bang2)
          record.rank = 0
        end
        
        #        if _is_parent[_coll_list] != 1 && _trow != nil
        #          record.vendor_name = UtilFormat.normalize(_trow.alt_name)
        #        else
        #          record.vendor_name = _row.alt_name
        #        end 
        record.vendor_name = collection.alt_name
        
        _tmp_type = UtilFormat.normalize(_type[_row.collection_id.to_i])
        if _row.dc_type != nil # and _row.dc_type.index(/[;\/\?\.]/) == nil
          _tmp_type = UtilFormat.normalize(_row.dc_type)
        end
        
        record.ptitle = UtilFormat.normalize(_row.title)
        if UtilFormat.normalize(_tmp_type) == 'Article'
          record.title = ""
          record.atitle = UtilFormat.normalize(_row.title)
        else
          record.title =  UtilFormat.normalize(_row.title)
          record.atitle =  ""
        end
        logger.debug("record title: " + record.title)
        record.hits = @total_hits
        record.issn =  ""
        record.isbn = ""
        record.abstract = UtilFormat.normalize(_row.description)
        record.date = _row.dc_date
        record.author = UtilFormat.normalize(_row.dc_creator)
        record.link = ""
        record.id = _row.oai_identifier.to_s + ID_SEPARATOR + _row.collection_id.to_s + ID_SEPARATOR + _search_id.to_s 
        record.doi = ""
        record.openurl = ""
        record.thumbnail_url = UtilFormat.normalize(_row.osu_thumbnail)
        
        if(INFOS_USER_CONTROL and !infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(infos_user,_row.collection_id)
          if(droits.id_perm == ACCESS_ALLOWED)
            record.direct_url = UtilFormat.normalize(_row.url)
          else
            record.direct_url = "";
          end
        else
          record.direct_url = UtilFormat.normalize(_row.url)          
        end
        
        record.static_url = ""
        record.subject = UtilFormat.normalize(_row.dc_subject)
        record.publisher = ""
        record.callnum = ""
        record.relation = ""
        record.contributor = ""
        record.coverage = ""
        record.rights = ""
        record.format = ""
        record.source = ""
        record.availability = _availability
        record.lang = UtilFormat.normalizeLang(UtilFormat.normalize(_row.dc_language))
        record.theme = "" # chkString(uniqString(_row.theme))
        record.category = ""
        record.identifier = ""
        record.vendor_url = collection.vendor_url
        
        record.material_type = PrimaryDocumentType.getNameByDocumentType(_tmp_type, _row.collection_id)
        if record.material_type.blank?
          record.material_type = UtilFormat.normalize(_type[_row.collection_id.to_i])
        end
        record.volume = ""
        record.issue = ""
        record.page = ""
        record.number = ""
        record.vendor_name = collection.alt_name
        record.coverage = _row.dc_coverage
        record.rights = _row.dc_rights
        record.format = _row.dc_format
        record.source = _row.dc_source
        record.publisher = _row.dc_publisher
        record.contributor = _row.dc_contributor
        record.volume = _row.osu_volume
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.actions_allowed = collection.actions_allowed
        record.issue_title = _row.dc_source
        
        _record[_x] = record
        _x = _x + 1
      end
      
      _oldset = _newset
      _count = _count + 1
      _tmp_max = _tmp_max + 1
    }
    
    logger.debug("Record Hits: #{_record.length} sur #{@total_hits}")
    
    return _record
  end
  
  def self.GetRecord(idDoc = nil, idCollection = nil, idSearch = "", infos_user = nil)
    
    if idDoc == nil or idCollection == nil
      logger.debug "Missing arguments to retrieve informations about the document"
      return nil
    end
    
    if idSearch == 0
      idSearch = ""
    end
    
    
    begin
      col = Collection.find(idCollection)
    rescue
      logger.error("Collection not found error")
      return nil
    end
    
    begin
      _query = "SELECT DISTINCT M.*, C.* FROM controls C LEFT JOIN metadatas M ON C.id = M.controls_id WHERE C.collection_id = '#{idCollection}' AND C.oai_identifier = '#{idDoc}';"
      logger.info("Requete : #{_query}")
      _results = Collection.find_by_sql(_query.to_s)
    rescue
      logger.debug("Query collection name error")
      return nil
    end
    
    begin
      # Get the results
      _results.each { |_row|
        
        if _row.oai_identifier.to_s == idDoc.to_s
          record = Record.new
          
          record.title = chkString(_row.title)
          record.ptitle =  chkString(_row.title)
          record.author = chkString(_row.dc_creator)
          record.subject = chkString(_row.dc_subject)
          record.abstract = chkString(_row.description)
          record.date = _row.dc_date
          record.material_type = PrimaryDocumentType.getNameByDocumentType(chkString(_row.dc_type), _row.collection_id)
          if record.material_type.blank?
            record.material_type = UtilFormat.normalize(col.mat_type)
          end
          #record.id = chkString(idSearch) + ";" + chkString(_row.collection_id) + ";"  + chkString(_row.oai_identifier)
          record.id = _row.oai_identifier.to_s + ID_SEPARATOR + _row.collection_id.to_s + ID_SEPARATOR + idSearch.to_s
          record.relation = chkString(_row.dc_relation)
          if(INFOS_USER_CONTROL and !infos_user.nil?)
            # Does user have rights to view the notice ?
            droits = ManageDroit.GetDroits(infos_user,_row.collection_id)
            if(droits.id_perm == ACCESS_ALLOWED)
              record.direct_url = UtilFormat.normalize(_row.url)
            else
              record.direct_url = "";
            end
          else
            record.direct_url = UtilFormat.normalize(_row.url)          
          end         
          record.thumbnail_url = chkString(_row.osu_thumbnail)
          record.volume = chkString(_row.osu_volume)
          record.issue = chkString(_row.osu_issue)
          
          record.vendor_name = col.alt_name
          record.coverage = _row.dc_coverage
          record.rights = _row.dc_rights
          record.format = _row.dc_format
          record.source = _row.dc_source
          record.publisher = _row.dc_publisher
          record.contributor = _row.dc_contributor
          record.volume = _row.osu_volume
          record.openurl = ""
          record.link = ""
          record.issn =  ""
          record.isbn = ""
          record.doi = ""
          record.static_url = ""
          record.callnum = ""
          record.page = ""
          record.number = ""
          record.atitle = ""
          record.vendor_url = col.vendor_url
          record.start = ""
          record.end = ""
          record.theme = "" # chkString(uniqString(_row.theme))
          record.category = ""
          record.holdings = ""
          record.raw_citation = ""
          record.oclc_num = ""
          record.availability = col.availability
          record.lang = UtilFormat.normalizeLang(UtilFormat.normalize(_row.dc_language))
          record.identifier = ""
          record.issue_title = _row.dc_source
          return record
        end
      }
      logger.debug("[OAISearchClass] No records matching")
    rescue Exception => e
      logger.error("[OAISearchClass]ERROR : #{e.message}")
      logger.error("[OAISearchClass]ERROR : #{e.backtrace}")
      logger.error("[OAISearchClass]Unable to retrieve informations for the document")
    end
    return nil
  end
  
end
