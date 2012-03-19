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

if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "" end
require ENV['LIBRARYFIND_HOME'] + 'components/mediaview/bpi_connector'

class MediaviewSearchClass < ActionController::Base
  
  if LIBRARYFIND_INDEXER.downcase == 'ferret' 
    require 'ferret'
    #  include FERRET
  elsif LIBRARYFIND_INDEXER.downcase == 'solr'
    require 'rubygems'
    require 'solr'
    include Solr
  end
  
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
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    
    logger.debug("[MEDIAVIEW] start search")
    
    _sTime = Time.now().to_f
    _lrecord = Array.new()
    keyword(_qstring[0])
    _type = ""
    _alias = ""
    _group = ""
    _vendor_url = ""
    _coll_list = ""
    _query = ""
    
    _coll_list =_collect.id 
    _type = _collect.mat_type
    _alias = _collect.alt_name
    _group = _collect.virtual
    _is_parent = _collect.is_parent
    _col_name = _collect.name
    _vendor_url = _collect.vendor_url
    _availability = _collect.availability 
    
    @bpi = Bpi_connector.new
    #				@bpi.setTheme(false); # without theme;
    @bpi.connect_to_postgresql(_collect.name, _collect.host, _collect.user, _collect.pass)
    logger.debug "Connection done to #{_collect.host} using #{_collect.name}"
    
    logger.debug "Searching in MediaView"
    _lrecord = RetrieveMediaview_Single(_last_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url, _is_parent, _col_name,_max.to_i, _collect.filter_query, infos_user, options, _availability)
    @bpi.disconnect
    logger.debug("Storing found results in cached results begin")
    
    _lprint = false; 
    if _lrecord != nil
      #record.concat(_lrecord)
      _lxml = CachedSearch.build_cache_xml(_lrecord)
      
      if _lxml != nil: _lprint = true end
      if _lxml == nil: _lxml = "" end
      
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
      logger.debug "Pas de resultats a stocker pour cette requette !!!!"
      _lxml = ""
      logger.debug("ID: " + _last_id.to_s)
      my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
    end
    
    logger.warn("#STAT# [MEDIAVIEW] base: " + _col_name.to_s + "[#{_coll_list}] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
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
  
  def self.RetrieveMediaview_Single(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name, _max, filter_query, infos_user=nil, options=nil, _availability=nil)
    htype			= {_coll_list => _type};
    halias 		= {_coll_list => _alias};
    hgroup 		= {_coll_list => _group};
    hvendor		= {_coll_list => _vendor_url};
    hparent		= {_coll_list => _is_parent};
    hcolname 	= {_coll_list => _collection_name};
    return  (RetrieveMediaview(_search_id, _query, _qtype, _qstring, _qoperator, htype, _coll_list, halias, hgroup, hvendor, hparent, hcolname, _max, filter_query, infos_user, options, _availability));
  end
  
  def self.RetrieveMediaview(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name, _max, filter_query, infos_user=nil, options=nil, _availability=nil)
    _x					= 0;
    _oldset 		= "";
    _newset 		= "";
    _count 			= 0;
    _tmp_max 		= 1;
    _start_time = Time.now();
    _objRec 		= RecordSet.new();
    _hits 			= Hash.new();
    _bfound 		= false;
    _Hthemes		= Hash.new();
    _dateEndNew = Hash.new()
    _dateIndexed = Hash.new()
    
    logger.debug("MediaView Search")
    
    if _max.class != 'Int': _max = _max.to_i end
    
    _keywords = _qstring.join("|")
    logger.debug("keywords enter")
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      _keywords = UtilFormat.normalizeFerretKeyword(_keywords)
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      _keywords = UtilFormat.normalizeSolrKeyword(_keywords)
    end
    if _keywords.slice(0,1) != "\""
      if _keywords.index(' OR ') == nil
        _keywords = _keywords.gsub("\"", "'")
      end
    end
    
    _keywords = _keywords.gsub("'", "\'")   
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      index = Ferret::Search::Searcher.new(LIBRARYFIND_FERRET_PATH)
      queryparser = Ferret::QueryParser.new()
      logger.debug("NOT PARENT: " + _collection_name[_coll_list])
      filter_query =  filter_query == nil ? "" : filter_query
      query_object = queryparser.parse("collection_name:(" + _collection_name[_coll_list] + ") AND " + _qtype.join("|") + ":\"" + _keywords + "\"" + " " + filter_query)
      logger.debug("FERRET QUERY: " + query_object.to_s)
      logger.debug "Recherche des documents en cours --"
      index.search_each(query_object, :limit => _max) do |doc, score|
        logger.debug("Found document id " + index[doc]["id"].to_s)
        
        # An item should have a score of 50% or better to get into this list
        break if score < 0.40 || index[doc]["id"].to_s == ""
        if _query != ""
          _query << " or "
        end
        _query << " apkid=" + index[doc]["id"].to_s 
        _Hthemes[index[doc]["id"].to_s] = index[doc]["theme"];
        _bfound = true;
      end
      index.close
      
    elsif LIBRARYFIND_INDEXER.to_s.downcase == 'solr'
      logger.debug("Entering SOLR")
      conn = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)

      raw_query_string, opt = UtilFormat.generateRequestSolr(_qtype, _qstring, _qoperator, filter_query, _is_parent[_coll_list], _coll_list, _collection_name[_coll_list], _max, options)
      
      logger.debug("RAW STRING: #{raw_query_string}")
      _r = conn.query(raw_query_string, opt)
      @total_hits = _r.total_hits
      logger.debug("TOTAL HITS: #{@total_hits}")
      _r.each do |hit|
        if _query != ""
          _query << " or "
        end
        _query << " apkid=" + hit["controls_id"].to_s
        _Hthemes[hit["controls_id"].to_s] = hit["theme"]
        _dateEndNew[hit["controls_id"].to_s] = hit["date_end_new"]
        _dateIndexed[hit["controls_id"].to_s] = hit["harvesting_date"]
        _bfound = true
      end
    end
    
    logger.debug("[MediaViewSearchClass] [RetrieveMediaView] _Hthemes : #{_Hthemes.inspect}");
    if _bfound == false 
      logger.debug("nothing found: " + _coll_list.to_s)
      return nil 
    end
    
    logger.debug("recuperation des resultats -- ")
    _sTime = Time.now().to_f
    _results = @bpi.get_parsed_data_from_ids(_query, _coll_list)
    logger.warn("#STAT# [MEDIAVIEW] base: [#{_coll_list}] recherche: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    logger.debug("-- recuperation des resultats")
    
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
          logger.debug("CHECK: #{_row.collection_id};#{UtilFormat.normalize(_row.oai_identifier)}")
          _newset = _row.alt_name
        end
      else
        logger.debug("CHECK: #{_row.collection_id};#{UtilFormat.normalize(_row.oai_identifier)}")
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
        logger.debug("creator: " + UtilFormat.normalize(_row.creator))
        logger.debug("date: " + UtilFormat.normalizeDate(_row.date))
        logger.debug("description: " + UtilFormat.normalize(_row.description))
        logger.debug("callnumber: " + UtilFormat.normalize(_row.callnumber))
        logger.debug("Publisher: " + UtilFormat.normalize(_row.publisher))
        logger.debug("Theme: " + UtilFormat.normalize(_row.theme))
        
        _theme = _Hthemes[_row.id.to_s];
        if (_theme.nil?)
          _theme = "";
        end
        logger.debug("[MediaViewSearchClass] [RetrieveMediaView] _row.id : #{_row.id}");
        logger.debug("[MediaViewSearchClass] [RetrieveMediaView] theme : #{_theme}");
        
        date_end_new = _dateEndNew[_row['dc_identifier'].to_s]
        if (!date_end_new.nil?)
          date_end_new = DateTime.parse(date_end_new)
        else
          date_end_new = ""
        end
        record.date_end_new = date_end_new
        
        harvesting_date = _dateIndexed[_row['dc_identifier'].to_s]
        if (!harvesting_date.nil?)
          harvesting_date = DateTime.parse(harvesting_date)
        else
          harvesting_date = ""
        end
        record.date_indexed = harvesting_date
          
        record.rank = _objRec.calc_rank({'title' => UtilFormat.normalize(_row.title),
                                         'atitle' => '',
                                         'creator'=>UtilFormat.normalize(_row.creator),
                                         'date'=>UtilFormat.normalizeDate(_row.date), 
                                         'rec' => UtilFormat.normalize(_row.description), 
                                         'theme' => UtilFormat.normalize(_theme), 
                                         'pos'=>1}, 
        @pkeyword)
        if _is_parent[_coll_list] != 1 && _trow != nil
          record.vendor_name = UtilFormat.normalize(_trow.alt_name)
        else
          record.vendor_name = UtilFormat.normalize(_row.alt_name) #_alias[_row['collection_id'].to_i]
        end 
        record.ptitle = UtilFormat.normalize(_row.title)
        record.title =  ""
        
        logger.debug("record title: #{record.title}")
        record.hits = @total_hits
        record.issn =  ""
        record.isbn = ""
        record.abstract = UtilFormat.normalize(_row.description) + "<br/>" + UtilFormat.normalize(_row.volume)
        record.date = UtilFormat.normalizeDate(_row.date)
        record.author = UtilFormat.normalize(_row.creator)
        record.link = _row.link
        record.id =  _row.id.to_s + ID_SEPARATOR + _row.collection_id.to_s + ID_SEPARATOR + _search_id.to_s
        record.doi = ""
        record.openurl = ""
        record.thumbnail_url = ""
        record.direct_url = ""
        record.static_url = ""
        record.relation = ""
        record.contributor = ""
        record.coverage = ""
        record.rights = UtilFormat.normalize(_row.rights)
        record.format = ""
        record.source = ""
        record.subject = UtilFormat.normalize(_row.subject)
        record.publisher = UtilFormat.normalize(_row.publisher)
        record.callnum = UtilFormat.normalize(_row.callnumber)
        record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(_row.type),_row.collection_id)
        if record.material_type.blank?
          record.material_type = UtilFormat.normalize(_type[_row.collection_id.to_i])
        end
        record.vendor_url = _vendor_url[_trow.id]
        record.theme = UtilFormat.normalize(uniqString(_theme))
        record.category = UtilFormat.normalize(_row.category)
        record.volume = ""
        record.issue = ""
        record.page = ""
        record.number = ""
        record.availability = _availability
        record.lang = UtilFormat.normalizeLang(_row.language)
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.identifier = ""
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
  
  def self.uniqString(str)
    if str == nil or str == ""
      return ""
    end
    theme = Array.new
    str = str.split(";")
    theme = str.uniq
    return theme.join(" ; ")
  end
  
  def self.GetRecord(idDoc = nil, idCollection = nil, idSearch = "", info_user = nil)
    
    if idDoc == nil or idCollection == nil
      logger.debug("Missing arguments to retrieve informations about the document")
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
      # Connect to the DB
      @conex = Bpi_connector.new
      @conex.connect_to_postgresql(col.name, col.host, col.user, col.pass)
      logger.debug("connection to DB done")
    rescue
      logger.debug("Connexion to DB failed : #{$!}")
      return nil
    end
    
    begin      
      # Query
      _query = ""
      _query << " apkid=" + idDoc.to_s
      _results = @conex.get_parsed_data_from_ids(_query, idCollection)
      logger.debug("Retrieved data from DB")
      @conex.disconnect
    rescue => e
      logger.error("Query for datas error. #{e.message}")
      return nil
    end
    
    begin
      
      _results.each { |_row|
        
        if _row.id.to_s == idDoc.to_s
          record = Record.new
          record.title = ""
          record.ptitle =  chkString(_row.title)
          record.abstract = chkString(_row.description) + "<br/>" + chkString(_row.volume)
          record.date = UtilFormat.normalizeDate(_row.date)
          record.author = chkString(_row.creator)
          record.link = chkString(_row.link)
          record.id = _row.id.to_s + ID_SEPARATOR  + _row.collection_id.to_s + ID_SEPARATOR   + idSearch.to_s
          record.doi = ""
          record.subject = chkString(_row.subject)
          record.publisher = chkString(_row.publisher)
          record.callnum = chkString(_row.callnumber)
          record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(_row.type), col.id)
          if record.material_type.blank?
            record.material_type = UtilFormat.normalize(col.mat_type)
          end
          record.volume = ""
          
          record.theme = chkString(uniqString(_row.theme))
          record.category = chkString(_row.category)
          record.issue = ""
          record.issn =  ""
          record.isbn = ""
          record.page = ""
          record.number = ""
          record.contributor = ""
          record.openurl = ""
          record.thumbnail_url = ""
          record.direct_url = ""
          record.static_url = ""
          record.rank = ""
          record.hits = ""
          record.atitle = ""
          record.source = ""
          record.relation = ""
          record.coverage = ""
          record.rights = chkString(_row.rights)
          record.format = ""
          record.vendor_name = UtilFormat.normalize(col.alt_name)
          record.vendor_url = ""
          record.start = ""
          record.end = ""
          record.holdings = ""
          record.raw_citation = ""
          record.oclc_num = ""
          record.lang = UtilFormat.normalizeLang(_row.language)
          record.identifier = ""
          record.availability = col.availability
          record.actions_allowed = col.actions_allowed
          return record
        end
      }
      logger.debug("No records matching")
    rescue => e
      logger.error("Unable to retrieve informations for the document. #{e.message}")
    end
    return nil
  end
  
end
