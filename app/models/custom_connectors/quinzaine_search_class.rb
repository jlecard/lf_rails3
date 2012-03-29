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

class QuinzaineSearchClass < ActionController::Base
  
  # require 'ferret'
  attr_reader :hits, :xml
  @total_hits = 0
  @pid = 0
  @pkeyword = ""
  def self.keyword (_string)
    @pkeyword = _string
  end
  
  def self.insert_id(_id) 
    @pid = _id
  end
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user=nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    
    logger.debug("[Quinzaine] [SearchCollection]");
    _sTime = Time.now().to_f
    
    _lrecord = Array.new()
    keyword(_qstring[0])
    _type = ""
    _alias = ""
    _group = ""
    _vendor_url = ""
    _coll_list = ""
    
    _query = "SELECT DISTINCT collections.id, collections.alt_name, controls.id as controls_id, controls.oai_identifier, controls.collection_id, controls.url, controls.title, controls.description, metadatas.dc_title, metadatas.dc_subject, metadatas.dc_creator, metadatas.dc_date, metadatas.dc_format, metadatas.osu_thumbnail, metadatas.dc_identifier,  metadatas.dc_publisher, metadatas.osu_volume, metadatas.osu_linking from collections LEFT JOIN controls ON collections.id=controls.collection_id  LEFT JOIN metadatas on controls.id = metadatas.controls_id where ("
    
    _coll_list =_collect.id 
    _type = _collect.mat_type
    _alias = _collect.alt_name
    _group = _collect.virtual
    _is_parent = _collect.is_parent
    _col_name = _collect.name
    _vendor_url = _collect.vendor_url
    _availability = _collect.availability
    
    #_lrecord = _obj_OAI.RetrieveOAI_Single(_last_id, _query, _qtype, _qstring, _type, _coll_list, _alias, _group, _vendor_url, _max.to_i)
    _lrecord = RetrieveQuinzaine_Single(_last_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url, _is_parent, _col_name,_max.to_i, _collect.filter_query, infos_user, options, _availability)
    logger.debug("Storing found results in cachecd results begin")
    _lprint = false; 
    if _lrecord != nil
      _lxml = CachedSearch.build_cache_xml(_lrecord)
      _lprint = true if _lxml != nil
      _lxml = "" if _lxml == nil
      
      #============================================
      # Add this info into the cache database
      #============================================
      if _last_id.nil?
        # FIXME:  Raise an error
        logger.debug("Error: _last_id should not be nil")
      else
        logger.debug("Save metadata")
        status = LIBRARYFIND_CACHE_OK
        if _lprint != true
          status = LIBRARYFIND_CACHE_EMPTY
        end
        my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, status, infos_user, @total_hits)
      end
    else
      logger.debug("save bad metadata")
      _lxml = ""
      logger.debug("ID: " + _last_id.to_s)
      my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
    end
    
    logger.debug("#STAT# [Quinzaine] base: #{_collect.name}[#{_coll_list}] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
    if _action_type != nil
      if _lrecord != nil
        return my_id, _lrecord.length, @total_hits
      else
        return my_id, 0, @total_hits
      end
    else
      return _lrecord
    end
  end
  
  def self.RetrieveQuinzaine_Single(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name,  _max, _filter_query=nil, infos_user=nil, options=nil, _availability=nil)
    htype = {_coll_list => _type}
    halias = {_coll_list => _alias}
    hgroup = {_coll_list => _group}
    hvendor = {_coll_list => _vendor_url}
    hparent = {_coll_list => _is_parent}
    hcolname = {_coll_list => _collection_name}
    
    logger.debug("Quinzaine_Qstring2: " + _qstring.length.to_s)
    return  RetrieveQuinzaine(_search_id, _query, _qtype, _qstring, _qoperator, htype, _coll_list, halias, hgroup, hvendor, hparent, hcolname, _max, _filter_query, infos_user, options, _availability)
  end
  
  def self.RetrieveQuinzaine(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name, _max, filter_query=nil, infos_user=nil, options=nil, _availability=nil)
    _x = 0
    _y = 0
    _oldset = ""
    _newset = ""
    _count = 0
    _tmp_max = 1
    _xml_tmp = ""
    _xml = ""
    _start_time = Time.now()
    _objRec = RecordSet.new()
    _hits = Hash.new()
    _dateIndexed = Hash.new()
    _bfound = false;
    
    logger.debug("Quinzaine Litteraire Search")
    
    if _max.class != 'Int': _max = _max.to_i end
    
    _keywords = _qstring.join("|")
    #if _keywords.slice(0,1)=='"'
    logger.debug("keywords enter")
    #    _keywords = _keywords.gsub(/^"*/,'')
    #    _keywords = _keywords.gsub(/"*$/,'')
    
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
    
    logger.debug("keywords exit")
    
    
    #_keywords = _keywords.gsub("'", "\'")   
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      #index = Ferret::Index::Index.new(:path => LIBRARYFIND_FERRET_PATH)
      #  index.search_each('collection_id:(' + _coll_list.to_s + ') AND ' + _qtype.join("|") + ':"' + _keywords + '"', :limit => _max) do |doc, score|
      index = Ferret::Search::Searcher.new(LIBRARYFIND_FERRET_PATH)
      #index = Ferret::Index::Index.new(:path => LIBRARYFIND_FERRET_PATH)
      queryparser = Ferret::QueryParser.new()
      if _is_parent[_coll_list] == 1 
        logger.debug("IS PARENT")
        query_object = queryparser.parse('collection_id:(' + _coll_list.to_s + ') AND ' + _qtype.join("|") + ':"' + _keywords + '"')
        logger.debug("FERRET QUERY: " + query_object.to_s)
      else
        logger.debug("NOT PARENT: " + _collection_name[_coll_list])
        query_object = queryparser.parse("collection_name:(" + _collection_name[_coll_list] + ") AND " + _qtype.join("|") + ":\"" + _keywords + "\"")
        logger.debug("FERRET QUERY: " + query_object.to_s)
      end
      index.search_each(query_object, :limit => _max) do |doc, score|
        logger.debug("Found document id " + index[doc]["controls_id"].to_s)
        
        # An item should have a score of 50% or better to get into this list
        break if score < 0.40
        _query << " controls.oai_identifier='" + index[doc]["controls_id"].to_s + "' or "
        _bfound = true;
        
      end 
      index.close
      
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      logger.debug("Entering SOLR")
      conn = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
      raw_query_string, opt = UtilFormat.generateRequestSolr(_qtype, _qstring, _qoperator, filter_query, _is_parent[_coll_list], _coll_list, _collection_name[_coll_list], _max, options)
      logger.debug("RAW STRING: " + raw_query_string)
      _response = conn.query(raw_query_string, opt)
      
      @total_hits = _response.total_hits
      
      _response.each do |hit|
        if defined?(hit["controls_id"]) == false
          break
        end 
        _query << " controls.id='" + hit["controls_id"].to_s + "' or "
        _dateIndexed[hit["controls_id"].to_s] = hit["harvesting_date"]
        _bfound = true
      end
    end
    
    if _bfound == false 
      logger.debug("nothing found: " + _coll_list.to_s)
      return nil 
    end
    _query = _query.slice(0, (_query.length- " or ".length)) + ") and controls.collection_id=#{_coll_list} order by controls.collection_id"
    
    _sTime = Time.now().to_f
    _results = Collection.find_by_sql(_query.to_s) 
    logger.debug("[SEARCH CLASS : query passed to mysql: #{_query.to_s}")
    logger.debug("#STAT# [QUINZAINE] base: [#{_coll_list}] search: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
    _record = Array.new()
    _i = 0
    _newset = ""
    _trow = nil
    _results.each { |_row|
      if _is_parent[_coll_list] != 1
        logger.debug("Find: " + _coll_list.to_s)
        _trow = Collection.find(_coll_list)
        if _trow != nil then
          logger.debug("COLLECTION RESOLVED")
          _newset = _trow.alt_name
          logger.debug('NEW COLLECTION NAME SET' + _newset)
        else
          logger.debug("CHECK: " +  _row.collection_id.to_s + ";" + UtilFormat.normalize(_row.oai_identifier))
          _newset = _row.alt_name
        end
      else
        logger.debug("CHECK: " +  _row.collection_id.to_s + ";" + UtilFormat.normalize(_row.oai_identifier))
        _newset = _row.alt_name
      end
      
      if _oldset != ""  
        if  _oldset != _newset
          _hits[_oldset] = _tmp_max-2 
          _count = 0
          _tmp_max = 1
        end
      elsif _oldset == ""
        _count = 0
      end
      
      if _tmp_max <= _max
        logger.debug("Prepping to print Title, etc.")
        record = Record.new()
        logger.debug("Title: " + UtilFormat.normalize(_row.title))
        logger.debug("creator: " + UtilFormat.normalize(_row.dc_creator))
        logger.debug("date: " + UtilFormat.normalizeDate(_row.dc_date))
        logger.debug("description: " + UtilFormat.normalize(_row.description))
        logger.debug("publisher: " + UtilFormat.normalize(_row.dc_publisher))
        
        harvesting_date = _dateIndexed[_row['dc_identifier'].to_s]
        if (!harvesting_date.nil?)
          harvesting_date = DateTime.parse(harvesting_date)
        else
          harvesting_date = ""
        end
        record.date_indexed = harvesting_date        
        
        record.rank = _objRec.calc_rank({'title' => UtilFormat.normalize(_row.title),
                                         'theme' => "", 
                                         'atitle' => '', 
                                         'creator'=>UtilFormat.normalize(_row.dc_creator), 
                                         'date'=>UtilFormat.normalizeDate(_row.dc_date), 
                                         'rec' => UtilFormat.normalize(_row.description), 
                                         'pos'=>1}, 
        @pkeyword)
        if _is_parent[_coll_list] != 1 && _trow != nil
          record.vendor_name = UtilFormat.normalize(_trow.alt_name)
        else
          record.vendor_name = UtilFormat.normalize(_row.alt_name) #_alias[_row['collection_id'].to_i]
        end 
        record.ptitle = UtilFormat.normalize(_row.title)
        if UtilFormat.normalize(_type[_row.collection_id.to_i]) == 'Article'
          record.title = UtilFormat.normalize(_row.dc_publisher)
          record.atitle = "" #UtilFormat.normalize(_row.dc_title)
        else
          record.title =  UtilFormat.normalize(_row.title)
          record.atitle =  ""
        end
        
        logger.debug("record title: " + record.title)
        record.issn =  ""
        record.isbn = ""
        record.abstract = UtilFormat.normalize(_row.description)
        record.date = UtilFormat.normalizeDate(_row.dc_date)
        record.author = UtilFormat.normalize(_row.dc_creator)
        logger.debug("[RetrieveQuinzaine] : Creating a record with identifier = #{_row.dc_identifier}")
        record.identifier = chkString(_row.dc_identifier)
        record.link = ""
        record.id = UtilFormat.normalize(_row.oai_identifier) + ID_SEPARATOR + _row.collection_id.to_s + ID_SEPARATOR + _search_id.to_s  
        record.doi = ""
        record.openurl = ""
        record.thumbnail_url = UtilFormat.normalize(_row.osu_thumbnail)
        
        if(INFOS_USER_CONTROL and !infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(infos_user,_row.collection_id)
          if(droits.id_perm == ACCESS_ALLOWED)
            record.direct_url = _row.dc_identifier
          else
            record.direct_url = "";
          end
        else
          record.direct_url = _row.dc_identifier          
        end
        
        record.static_url = ""
        record.subject = UtilFormat.normalize(_row.dc_subject)
        record.publisher = UtilFormat.normalize(_row.dc_publisher)
        record.callnum = ""
        record.relation = ""
        record.contributor = ""
        record.coverage = ""
        record.rights = ""
        record.format = ""
        record.source = ""
        record.theme = "" # chkString(uniqString(_row.theme))
        record.category = ""
        record.lang = UtilFormat.normalizeLang("fr")
        record.hits = @total_hits
        record.availability = _availability
        record.ptitle = UtilFormat.normalize(_row.title)
        record.vendor_url = _vendor_url[_row.collection_id]
        record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(_type[_row.collection_id.to_i]),_row.collection_id)
        if record.material_type.blank?
          record.material_type = UtilFormat.normalize(_type[_row.collection_id.to_i])
        end
        record.volume = ""
        record.issue = ""
        record.page = UtilFormat.normalize(_row.osu_volume.to_s)
        record.number = ""
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.actions_allowed = _trow.actions_allowed
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
  
  # check the state of variables
  def self.chkString(_str)
    begin
      if _str == nil
        return ""
      end
      if _str.is_a?(Numeric)
        return _str.to_s
      end
      return _str.chomp
    rescue
      return ""
    end
  end
  
  def self.GetRecord(idDoc = nil, idCollection = nil, idSearch = "", info_user = nil)
    
    #logger.debug("[GetRecord] : idDoc = #{idDoc}")
    if idDoc == nil or idCollection == nil
      logger.debug "-quinzaine litterraire search class-Missing arguments to retrieve informations about the document"
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
      _query = "SELECT DISTINCT metadatas.*, controls.* FROM controls LEFT JOIN metadatas ON controls.id = metadatas.controls_id WHERE controls.collection_id = '#{idCollection}' AND controls.oai_identifier = '#{idDoc}';"
      logger.debug("[GetRecord]: query used on metadatas table: #{_query}")
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
          record.ptitle = chkString(_row.dc_title)
          record.title =  chkString(_row.dc_title)
          record.author = chkString(_row.dc_creator)
          record.subject = chkString(_row.dc_subject)
          record.abstract = chkString(_row.dc_description)
          record.publisher = chkString(_row.dc_publisher)
          record.contributor = chkString(_row.dc_contributor)
          record.date = UtilFormat.normalizeDate(_row.dc_date)
          record.material_type = PrimaryDocumentType.getNameByDocumentType(chkString(_row.dc_type), _row.collection_id)
          if record.material_type.blank?
            record.material_type = UtilFormat.normalize(col.atl_name)
          end
          record.format = chkString(_row.dc_format)
          record.id = UtilFormat.normalize(_row.oai_identifier) + ID_SEPARATOR + _row.collection_id.to_s + ID_SEPARATOR + idSearch.to_s
          record.source = chkString(_row.dc_source)
          record.relation = chkString(_row.dc_relation)
          record.coverage = chkString(_row.dc_coverage)
          record.rights = chkString(_row.dc_rights)        
          #          record.link = chkString(_row.osu_linking)
          record.openurl = chkString(_row.osu_openurl)
          record.thumbnail_url = chkString(_row.osu_thumbnail)
          record.volume = chkString(_row.osu_volume)
          record.issue = chkString(_row.osu_issue)
          record.identifier = chkString(_row.dc_identifier)
          
          record.theme = "" # chkString(uniqString(_row.theme))
          record.category = ""
          record.issn =  ""
          record.isbn = ""
          record.doi = ""
          record.direct_url = record.identifier          
          record.static_url = ""
          record.callnum = ""
          record.page = ""
          record.number = ""
          record.rank = ""
          record.hits = ""
          record.atitle = ""
          record.vendor_name = ""
          record.vendor_url = ""
          record.start = ""
          record.end = ""
          record.holdings = ""
          record.raw_citation = ""
          record.oclc_num = ""
          record.availability = col.availability
          record.lang = UtilFormat.normalizeLang("fr")
          record.actions_allowed = col.actions_allowed
          return record
        end
      }
      logger.debug("No records matching")
    rescue
      logger.debug("Unable to retrieve informations for the document")
    end
    return nil
  end  
end
