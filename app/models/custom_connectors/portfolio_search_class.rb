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
require ENV['LIBRARYFIND_HOME'] + 'components/portfolio/portfolio_theme';

class PortfolioSearchClass < ActionController::Base
  
  require 'rubygems'
  begin
    require 'dbi'  
  rescue LoadError => e
    logger.warn("No dbi gem")
  end
  
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
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user=nil, options=nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    begin
      logger.debug("[PortfolioSearchClass] [SearchCollection]");
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
      
      logger.debug "[PortfolioSearchClass] [SearchCollection] Searching in Portfolio"
      _lrecord = RetrievePortfolio_Single(_last_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url, _is_parent, _col_name,_max.to_i, _collect.filter_query, infos_user, options, _availability)
      logger.debug("[PortfolioSearchClass] [SearchCollection] Storing found results in cached results begin")
      
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
          logger.warn("[PortfolioSearchClass] [SearchCollection] Error: _last_id should not be nil")
        end
        logger.debug("[PortfolioSearchClass] [SearchCollection] Save metadata")
        status = LIBRARYFIND_CACHE_OK
        if _lprint != true
          status = LIBRARYFIND_CACHE_EMPTY
        end
        my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, status, infos_user, @total_hits)
        #end
      else
        logger.debug "[PortfolioSearchClass] [SearchCollection] Pas de resultats a stocker pour cette requette !!!!"
        _lxml = ""
        logger.debug("[PortfolioSearchClass] [SearchCollection] ID: " + _last_id.to_s)
        my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
      end
      
      logger.debug("#STAT# [PORTFOLIO] base: " + _col_name.to_s + "[#{_coll_list}] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      
      if _action_type != nil
        if _lrecord != nil
          return my_id, _lrecord.length, @total_hits
        else
          return my_id, 0, @total_hits
        end
      else
        return _lrecord
      end
    rescue => e
      logger.error("[PortfolioSearchClass][SearchCollection] Error : " + e.message)
      logger.error("[PortfolioSearchClass][SearchCollection] Trace : " + e.backtrace.join("\n"))
    end
  end
  
  def self.RetrievePortfolio_Single(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name, _max, filter_query, infos_user=nil, options=nil, _availability=nil)
    htype = {_coll_list => _type}
    halias = {_coll_list => _alias}
    hgroup = {_coll_list => _group}
    hvendor = {_coll_list => _vendor_url}
    hparent = {_coll_list => _is_parent}
    hcolname = {_coll_list => _collection_name}
    logger.debug("[PortfolioSearchClass] [RetrievePortfolio_Single] Portfolio_Qstring2: " + _qstring.length.to_s)
    return  RetrievePortfolio(_search_id, _query, _qtype, _qstring, _qoperator, htype, _coll_list, halias, hgroup, hvendor, hparent, hcolname, _max, filter_query, infos_user, options, _availability)
  end
  
  def self.RetrievePortfolio(_search_id, _query, _qtype, _qstring, _qoperator, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name, _max, filter_query, infos_user=nil, options=nil, _availability=nil)
    _x = 0
    _count = 0
    _tmp_max = 1
    _start_time = Time.now()
    _objRec = RecordSet.new()
    _bfound = false
    _Hthemes = Hash.new()
    _dateEndNew = Hash.new()
    _dateIndexed = Hash.new()
    
    logger.debug("[PortfolioSearchClass] [RetrievePortfolio]")
    
    if _max.class != 'Int': _max = _max.to_i end
    
    _keywords = _qstring.join("|")
    #if _keywords.slice(0,1)=='"'
    logger.debug("[PortfolioSearchClass] [RetrievePortfolio] keywords enter : #{_keywords.to_s}")
    #    _keywords = _keywords.gsub(/^"*/,'')
    #    _keywords = _keywords.gsub(/"*$/,'')
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      _keywords = UtilFormat.normalizeFerretKeyword(_keywords)
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      _keywords = UtilFormat.normalizeSolrKeyword(_keywords)
      logger.debug("[PortfolioSearchClass] [RetrievePortfolio] keywords normalized : #{_keywords.to_s}")
    end
    # if _keywords.slice(0,1) != "\""
      # if _keywords.index(' OR ') == nil
        # _keywords = _keywords.gsub("\"", "'")
        # #I think this is a problem.
        # #_keywords = "\"" + _keywords + "\""
      # end
    # end
    logger.debug("[PortfolioSearchClass] [RetrievePortfolio] keywords exit : #{_keywords.to_s}")
    #else  
    #   _keywords = '"' + _keywords + '"' 
    #end 
    
    #_keywords = _keywords.gsub("'", "\'")   
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      index = Ferret::Search::Searcher.new(LIBRARYFIND_FERRET_PATH)
      queryparser = Ferret::QueryParser.new()
      logger.debug("[PortfolioSearchClass] [RetrievePortfolio] NOT PARENT: " + _collection_name[_coll_list])
      filter_query =  filter_query == nil ? "" : filter_query
      query_object = queryparser.parse("collection_name:(" + _collection_name[_coll_list] + ") AND " + _qtype.join("|") + ":\"" + _keywords + "\"" + " " + filter_query)
      logger.debug("[PortfolioSearchClass] [RetrievePortfolio] FERRET QUERY: " + query_object.to_s)
      logger.debug "[PortfolioSearchClass] [RetrievePortfolio] Recherche des documents en cours --"
      index.search_each(query_object, :limit => _max) do |doc, score|
        logger.debug("[PortfolioSearchClass] [RetrievePortfolio] Found document id " + index[doc]["id"].to_s)
        
        # An item should have a score of 50% or better to get into this list
        break if score < 0.40 || index[doc]["id"].to_s == ""
        if _query != ""
          _query << " or "
        end
        _query << " dc_identifier=" + index[doc]["id"].to_s 
        _Hthemes[hit[doc]["id"].to_s] = hit[doc]["theme"]
        _bfound = true;
      end
      index.close
      
    elsif LIBRARYFIND_INDEXER.to_s.downcase == 'solr'
      logger.debug("[PortfolioSearchClass] [RetrievePortfolio] Entering SOLR")
      conn = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
      
      raw_query_string, opt = UtilFormat.generateRequestSolr(_qtype, _qstring, _qoperator, filter_query, _is_parent[_coll_list], _coll_list, _collection_name[_coll_list], _max, options)
      logger.info("[PortfolioSearchClass] [RetrievePortfolio] RAW STRING: " + raw_query_string)
      
      _response = conn.query(raw_query_string, opt)
      @total_hits = _response.total_hits
      logger.info("[PortfolioSearchClass][RetrievePortfolio] SOLR RESPONSE GIVE #{@total_hits}")
      _query = Array.new
      _response.each do |hit|
        if _query != ""
          _query.push(hit["controls_id"].to_s)
        end
        
        logger.debug("[PortfoliosearchClass] [RetrievePortfolio] [controls_id] : " + hit["controls_id"] + " theme : " + hit["theme"]);
        _Hthemes[hit["controls_id"].to_s] = hit["theme"]
        _dateEndNew[hit["controls_id"].to_s] = hit["date_end_new"]
        _dateIndexed[hit["controls_id"].to_s] = hit["harvesting_date"]
        _bfound = true
      end
    end
    logger.debug("[PortfoliosearchClass] [RetrievePortfolio] [hash Themes] : " + _Hthemes.inspect);
    
    if _bfound == false 
      logger.debug("[PortfolioSearchClass] [RetrievePortfolio] nothing found: " + _coll_list.to_s)
      return nil 
    end
    logger.debug("[PortfolioSearchClass] [RetrievePortfolio] recuperation des resultats -- ")
    _sTime = Time.now().to_f
    
    time_start = Time.now.to_f
    rows = Metadata.find(:all, :limit=> _max, :conditions=>{:collection_id=>_coll_list.to_i, :dc_identifier=>_query }, :include=>[:volumes, :portfolio_data])
    time_end = Time.now.to_f
    logger.debug("PORTFOLIO_SEARCH_CLASS => MetadataFind took #{time_end - time_start} ms")
    logger.debug("#STAT# [PORTFOLIO] base: [#{_coll_list}] recherche: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    logger.debug("-- recuperation des resultats")
    
    _record = Array.new()
    _i = 0
    
    begin
      collection = Collection.getCollectionById(_coll_list)
    rescue => e
      logger.error("[PortfolioSearchClass][RetrievePortfolio] Collection not found")
      raise e
    end
    start_loop_time = Time.now.to_f
    rows.each do |_row|
      begin
        logger.debug("[PortfolioSearchClass] [RetrievePortfolio] CHECK: " +  _coll_list.to_s + ";" + UtilFormat.normalize(_row['dc_identifier'].to_s))
        
        if _tmp_max <= _max
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] Prepping to print Title, etc.")
          record = Record.new()
          
          logger.debug("[PortfoliosearchClass] [RetrievePortfolio] [row.id] : " + _row['dc_identifier'].to_s)
          theme = _Hthemes[_row['dc_identifier'].to_s]
          logger.debug("[PortfoliosearchClass] [RetrievePortfolio] [theme before test] : " + theme.to_s)
          if (theme.nil?)
            theme = ""
          end
          
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
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] PORTFOLIO_DATA => #{_row.portfolio_data.inspect}")
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] Title: " + _row['dc_title'])
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] creator: " + UtilFormat.normalize(_row['dc_creator']))
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] date: " + UtilFormat.normalizeDate(_row['dc_date']))
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] description: " + UtilFormat.normalize(_row['dc_description']))
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] theme " + theme)
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] Publisher: " + UtilFormat.normalize(_row['dc_publisher']))
          record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(_row['dc_type']), _coll_list)
          if record.material_type.blank?
            record.material_type = UtilFormat.normalize(_type[_coll_list])
          end
           
          if !_row.portfolio_data.nil?
            indice = _row.portfolio_data.indice
          else
            indice = ""
          end
          record.rank = _objRec.calc_rank({'title' => _row['dc_title'],
                                           'atitle' => _row['dc_title'],
                                           'creator'=>UtilFormat.normalize(_row['dc_creator']),
                                           'date'=>UtilFormat.normalizeDate(_row['dc_date']), 
                                           'rec' => UtilFormat.normalize(_row['dc_description']), 
                                           'theme' => theme, 
                                           'subject' => _row['dc_subject'],
                                           'indice' => indice,
                                           'material_type' => record.material_type,
                                           'special' => true,
                                           'pref' => "BPI",
                                           'url' => "BPI",
                                           'pos'=>1}, 
          @pkeyword)
          record.ptitle= chkString(_row['dc_title'])
          record.title = chkString(_row['dc_title'])
          record.hits = @total_hits
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] record title: " + _row['dc_title'])
          record.issn =  chkString(_row.portfolio_data.issn) unless _row.portfolio_data.blank?
          record.isbn = chkString(_row.portfolio_data.isbn.split(" @;@ ")[0]) unless _row.portfolio_data.blank?
          record.abstract = chkString(UtilFormat.normalize(_row['dc_description']))
          record.date = UtilFormat.normalizeDate(_row['dc_date'])
          record.author = chkString(UtilFormat.normalize(_row['dc_creator']))
          
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] vendor_name:" + _alias[_coll_list])
          record.vendor_name = chkString(UtilFormat.normalize(_alias[_coll_list]))
          # record.link = chkString(_row['bpi_dm_lien_lib'])
          record.id =  _row['dc_identifier'].to_s + ID_SEPARATOR + _coll_list.to_s + ID_SEPARATOR + _search_id.to_s
          record.doi = ""
          record.openurl = ""
          record.thumbnail_url= ""
          record.static_url = ""
          record.relation = _row['dc_relation']
          record.contributor = _row['dc_contributor']
          record.coverage = _row['dc_coverage']
          record.rights = _row['dc_rights']
          record.format = chkString(UtilFormat.normalize(_row['dc_format']))
          record.source = ""
          logger.debug("PORTFOLIO SUBJECT before: #{_row['dc_subject']}")
          record.subject = chkString(UtilFormat.normalize(_row['dc_subject']))
          logger.debug("PORTFOLIO SUBJECT after_: #{record.subject}")
          record.publisher = chkString(UtilFormat.normalize(_row['dc_publisher']))
          record.callnum = ""
          record.vendor_url = _vendor_url[_coll_list]
          record.theme = theme
          record.category = _row.portfolio_data.genre
          record.binding = _row.portfolio_data.binding
          record.issue = _row.portfolio_data.last_issue
          record.issues = _row.portfolio_data.issues.split('@;@').join(';') unless _row.portfolio_data.issues.nil?
          logger.debug("[PortfolioSearchClass] [RetrievePortfolio] bindings etc: #{record.volume} -- #{record.issues} -- #{record.issue}")
          record.page = ""
          record.number = ""
          record.lang = UtilFormat.normalizeLang(chkString(UtilFormat.normalize(_row['dc_language'])))
          record.start = _start_time.to_f
          record.end = Time.now().to_f
          record.identifier = ""
          
          record.indice = chkString(_row.portfolio_data.indice)
          record.issue_title = _row.portfolio_data.issue_title
          record.conservation = _row.portfolio_data.conservation
          # examplaires
          broadcast_group = _row.portfolio_data.broadcast_group.split(";") if !_row.portfolio_data.broadcast_group.blank?
          record.examplaires = createExamplaires(_row.volumes, _row.collection_id, infos_user, broadcast_group)
          record.examplaires.each do |ex|
            if ex.availability.match(/consultable sur ce poste/i)
              record.availability = defineAvailability(collection.availability, record.format)
	      if record.availability.match(/online/i)
              	 break
	      end
	    elsif ex.availability.match(/Disponible/i) or ex.availability.match(/bureau/i)
	      record.availability = defineAvailabilityDisp(collection.availability, record.format)
              if record.availability.match(/onshelf/i)
                break
              end
	    end
          end
          record.actions_allowed = collection.actions_allowed         
          _record[_x] = record
          _x = _x + 1
          
        end
        
      rescue Exception => e
        logger.error("#{e.message}")
        logger.error("#{e.backtrace.join("\n")}")
      end
      _count = _count + 1
      _tmp_max = _tmp_max + 1
    end #while fetch
    end_loop_time = Time.now.to_f
    logger.debug("TOTAL_LOOP_TIME: #{end_loop_time - start_loop_time}")
    logger.debug("Record Hits: #{_record.length} sur #{@total_hits}")
    
    return _record
  end
  
  # check the state of variables
  def self.chkString(_str)
    begin
      if _str == nil
        return ""
      end
      word = _str.to_s
      word = word.chomp(",")
      word = word.chomp("/")
      word = word.chomp
      return word
    rescue Exception => ex
      logger.error("[PortfolioSearchClass] [chkString] str:#{_str} word : #{word} msg:#{ex.backtrace}")
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
  
  def self.GetRecord(idDoc = nil, idCollection = nil, idSearch = "", infos_user = nil)
    _sTime = Time.now().to_f
    if idDoc == nil or idCollection == nil
      logger.error("[PortfolioSearchClass] [GetRecord] Missing arguments to retrieve informations about the document")
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
      # Query
      _row = Metadata.find(:first, :conditions=>{:collection_id=>col.id, :dc_identifier=>idDoc.to_s})
      logger.debug("[PortfolioSearchClass] [GetRecord] Retrieved data from DB")
    rescue Exception=>e
      logger.error("[PortfolioSearchClass] [GetRecord] Query for datas error #{e.message}")
      logger.error('[PortfolioSearchClass] [GetRecord] backtrace #{e.backtrace.join("\n"}')
      return nil
    end
    
    begin
      _themePortfolio = PortfolioTheme.new(@conn, logger, col.name)
      logger.debug("#STAT# [Portfolio] get record DB : " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      if !_row.nil? and _row['dc_identifier'].to_s == idDoc.to_s
        record = Record.new
        
        record.title = chkString(_row['dc_title'])
        record.ptitle =  chkString(_row['dc_title'])
        record.abstract = chkString(_row['dc_description'])
        record.date = UtilFormat.normalizeDate(_row['dc_date'])
        record.author = chkString(_row['dc_creator'])
        desc = _row['dc_description']
        if !desc.blank?
          tab = desc.split("@;@")
          if !tab.empty? and tab[0].starts_with?("http://")
            record.link = tab[0]
          end
        end
        record.id = _row['dc_identifier'].to_s + ";" + idCollection.to_s + ";"  + idSearch.to_s
        record.doi = ""
        logger.debug("PORTFOLIO SUBJECT before: #{_row['dc_subject']}")
        record.subject = chkString(_row['dc_subject'])
        logger.debug("PORTFOLIO SUBJECT after: #{record.subject}")
        record.publisher = chkString(_row['dc_publisher'])
        record.callnum = "" #chkString(_row['bpi_loca'])
        record.material_type = PrimaryDocumentType.getNameByDocumentType(chkString(_row['dc_type']), idCollection)
        if record.material_type.blank?
          record.material_type = UtilFormat.normalize(col.mat_type)
        end
        logger.debug("PORTFOLIO: THEME = #{_row.portfolio_data.theme}")
        if !_row.portfolio_data.theme.blank?
          #record.theme = _themePortfolio.translateTheme(_row.portfolio_data.theme)
        end
        record.category = _row.portfolio_data.genre 
        record.issue = _row.portfolio_data.last_issue
        record.binding = _row.portfolio_data.binding
        record.issues = _row.portfolio_data.issues.split('@;@').join(';') unless _row.portfolio_data.issues.nil? 
        logger.debug("[PortfolioSearchClass] [GetRecord] bindings etc: #{record.volume} -- #{record.issues} -- #{record.issue}")
        record.issn =  _row.portfolio_data.issn
        record.isbn = _row.portfolio_data.isbn
        record.page = ""
        record.number = ""
        record.contributor = chkString(_row['dc_contributor'])
        record.openurl = ""
        record.thumbnail_url = ""
        record.static_url = ""
        record.rank = ""
        record.hits = ""
        record.atitle = ""
        record.source = chkString(_row['dc_source'])
        record.relation = chkString(_row['dc_relation'])
        record.coverage = chkString(_row['dc_coverage'])
        record.rights = chkString("#{chkString(_row['dc_rights'])} #{chkString(_row.portfolio_data.copyright)} #{chkString(_row.portfolio_data.license_info)}")
        record.format = chkString(UtilFormat.normalize(_row['dc_format']))
        record.vendor_name = chkString(UtilFormat.normalize(col.alt_name))
        record.vendor_url = ""
        record.start = ""
        record.end = ""
        record.holdings = ""
        record.raw_citation = ""
        record.oclc_num = ""
        record.availability = defineAvailability(col.availability, record.format)
        record.lang = UtilFormat.normalizeLang(chkString(UtilFormat.normalize(_row['dc_language'])))
        record.identifier = ""
        record.is_available = _row.portfolio_data.is_available
        
        record.indice = chkString(_row.portfolio_data.indice)
        record.issue_title = _row.portfolio_data.issue_title
        record.conservation = _row.portfolio_data.conservation
        # examplaires
        broadcast_groups = _row.portfolio_data.broadcast_group.split(";") if !_row.portfolio_data.broadcast_group.blank?
        record.examplaires = createExamplaires(_row.volumes, _row.collection_id, infos_user, broadcast_groups)
        record.actions_allowed = col.actions_allowed
        logger.debug("#STAT# [Portfolio] get record : total : " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
        return record
      end
      logger.debug("[PortfolioSearchClass] [GetRecord] No records matching")
    rescue Exception => e
      logger.error("[PortfolioSearchClass] [GetRecord] Unable to retrieve informations for the document : #{$!}")
      logger.error("[PortfolioSearchClass] [GetRecord] Error : #{e.message}")
      logger.error("[PortfolioSearchClass] [GetRecord] Backtrace #{e.backtrace.join("\n")}")
    end
    return nil
  end
  
  def self.defineAvailability(default_collection, value)
    if value.blank?
      return default_collection
    end
    
    if value.match(/en ligne/i)
      return "online"
    elsif value.match(/DVD/i)
      return "online"
    elsif value.match(/CD-ROM/i)
      return "online"
    elsif value.match(/\sCD\s/i)
      return "online"
    elsif value.match(/cédérom/i)
      return "online"
    elsif value.match(/internet/i)
      return "online"
    elsif value.match(/vidéo/i)
      return "online"
    elsif value.match(/papier/i)
      return "onshelf"
    elsif value.match(/microforme/i)
      return "onshelf"    
    elsif value.match(/microfilm/i)
      return "onshelf"    
    elsif value.match(/imprimé/i)
      return "onshelf"
    else
      return default_collection
    end
  end 

  def self.defineAvailabilityDisp(default_collection, value)
    if value.blank?
      return default_collection
    end
    
    if value.match(/papier/i)
      return "onshelf"
    elsif value.match(/microforme/i)
      return "onshelf"    
    elsif value.match(/microfilm/i)
      return "onshelf"    
    elsif value.match(/imprimé/i)
      return "onshelf"
    else
      return default_collection
    end
  end 
  
  def self.formatCote(cote)
    if cote.blank?
      return ""
    end
    
    return cote.gsub("\"","\\\"").gsub("(","\(").gsub(")","\)")
  end
  
  def self.createExamplaires(volumes, collection_id=5, infos_user=nil, broadcast_groups = nil)
    begin
      array = Array.new
      volumes.each do |v|
        if v.blank?
          next
        end
        ex = Struct::Examplaire.new()
        v.attributes.each do |var,val|
          a_var = "@#{var}"
          ex.instance_variable_set(a_var, val)
        end
        # Check if access is free or requires reservation
        location_groups = Array.new
        if !infos_user.nil?
          location_groups = ManageRole.GetBroadcastGroups(infos_user)
        end
          
        if !ex.object_id.blank? and !ex.source.blank?
          ex.call_num =""
          free_groups = FREE_ACCESS_GROUPS.split(",")
          free_groups.each do |group|
            logger.debug("[PortfolioSearchClass] [createExemplaire] group : #{group}\nLocation group : #{location_groups.inspect}\nBROADCAST : #{broadcast_groups.inspect}")
            if !location_groups.nil? and location_groups.include?(group) and broadcast_groups.include?(group)
              ex.availability = "Consultable sur ce poste"
              break
            elsif location_groups.nil? and broadcast_groups.include?(group)
              ex.availability = "Consultable sur un poste de la bibliothèque"
              break
            elsif !location_groups.nil? and !location_groups.include?(group) and broadcast_groups.include?(group)
              ex.availability = "Consultable sur un poste en accès libre"
              break
            else
              ex.availability = "Consultable sur un poste soumis à réservation"
            end
          end
        end
        ### Check user rigths
        if(INFOS_USER_CONTROL and !infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(infos_user,collection_id)
          if(droits.id_perm != ACCESS_ALLOWED)
            ex.object_id = 0
            ex.source = ""
          end
          # Now check display_groups
          logger.debug("[PortfolioSearchClass] [createExemplaire] location_groups : #{location_groups}") 
          if broadcast_groups
            broadcast_groups.each do |broadcast_group|
              logger.debug("[PortfolioSearchClass] [createExemplaire] broadcast_group : #{broadcast_group}")
              if !location_groups.nil? and !location_groups.include?(broadcast_group)  
                ex.object_id = 0
                ex.source = ""
              end
              
            end
          end
          # Now check access type for resource link (inhouse/external access)
          if !ex.launch_url.blank?
            if infos_user.location_user.blank? 
              ex.object_id = 0
              ex.source = ""
              if ex.availability.match(/Consultable/i) and !ex.link.blank?
                ex.availability = "Consultable sur ce poste"
              end              
            else
              ex.link = ""
            end
          end

        end
        array.push(ex)
      end
      return array
    rescue => e
      logger.error("[PortfolioSearchClass] [createExemplaire] error : #{e.message}")
      logger.error("[PortfolioSearchClass] [createExemplaire] error : #{e.backtrace.join("\n")}")
      return []
    end
  end
  
  
  # params:
  #   docs_to_check : Hash
  #     having format {doc_collection_id1 => ["doc1","doc2",..], doc_collection_id2 => ["doc5","doc6",..],...} 
  def self.getExamplairesForNotices(docs_to_check)
    logger.debug("[PortfolioSeachClass][getExamplairesForNotices] docs_to_check : #{docs_to_check.inspect}")
    docs_examplaires = Hash.new()
    begin
      docs_to_check.each do |doc_collection_id, docs|
        row = Collection.find_by_id(doc_collection_id)
        logger.debug("[PortfolioSearchClass][getExamplairesForNotices] connection type for collection #{doc_collection_id} => #{row.conn_type}")        
        if(row.conn_type == "portfolio")
          query = "";
          if(!row.nil?)
            logger.debug("Host : #{row.host}")
            logger.debug("ID: #{row.id} Db name: #{row.name}")
            
            logger.debug("[portfolio_harvester] Connection done to #{row.host} using #{row.name}")
            
            _themePortfolio = PortfolioTheme.new(@conn, logger, row.name)
            
            docs_ids = docs.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
            
            Metadata.find(:all, :conditions=>{:dc_identifier=>docs_ids,:collection_id=>doc_collection_id}).each do |portRow|
              begin
                doc_id = "#{portRow['dc_identifier']}#{ID_SEPARATOR}#{portRow['collection_id']}"
                examplaires = []
                examplaires = createExamplaires(portRow.volumes)
                docs_examplaires[doc_id] = {:examplaires => examplaires}
              rescue => e
                logger.error("[portfolio_search_class][getExamplairesForNotices] Errors while fetching data : #{e.message}")
                logger.error("[portfolio_search_class][getExamplairesForNotices] Trace : #{e.backtrace.join("\n")}")
              end 
            end
          end
        end
      end
    rescue => e
      logger.error("[portfolio_search_class][getExamplairesForNotices] Error : " + e.message)
      logger.error("[portfolio_search_class][getExamplairesForNotices] Trace : " + e.backtrace.join("\n"))
    end
    return docs_examplaires
    
  end
  
end
