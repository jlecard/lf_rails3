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

class OaiSearchClass
  include SearchClassHelper

  attr_reader :hits, :xml
  attr_accessor :list_of_ids

  @total_hits = 0
  @pid = 0
  @pkeyword = ""
  
  def logger
    ActiveRecord::Base.logger 
  end

  def set_keywords(_keywords)
    if _keywords.index("site:")!= nil
      _site = _keywords.slice(_keywords.index("site:"), _keywords.length - _keywords.index("site:")).gsub("site:", "")
      _keywords = _keywords.slice(0, _keywords.index("site:")).chop
      if _site.index('"') != nil
        _site = _site.gsub('"', "")
        _keywords << '"'
      end
    elsif _keywords.index("sitepref:") != nil
      _sitepref = _keywords.slice(_keywords.index("sitepref:"), _keywords.length - _keywords.index("sitepref:")).gsub("sitepref:", "")
      logger.debug("[#{self.class}][set_keywords] SITE PREF: " + _sitepref)
      _keywords = _keywords.slice(0, _keywords.index("sitepref:")).chop
      if _sitepref.index('"') != nil
        _sitepref = _sitepref.gsub('"', "")
        _keywords << '"'
      end
    end
    return _keywords
  end

  def search
    _x = 0
    _oldset = ""
    _newset = ""
    _count = 0
    _tmp_max = 1
    _start_time = Time.now()
    _objRec = RecordSet.new()
    _hits = Hash.new()
    @date_indexed = {}
    logger.debug("OAI Search")

    _keywords = @query_string.join("|")
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

    _keywords = set_keywords(_keywords)
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
        @collection.name = @collection.name.gsub("http_//", "")

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
      @list_of_ids ||= solr_request
      return nil if !@list_of_ids
    end

    rows = Metadata.find(:all, :limit=> @max, :conditions=>{:collection_id=>@collection.id, :dc_identifier=>@list_of_ids })
    if @total_hits and @total_hits > rows.count
      logger.error("Found more results in solr than in database. Maybe collection #{@collection.name}, #{@collection.id} should be reharvested")
    end
    @total_hits = rows.count
    _i = 0
    _newset = ""
    _trow = nil

    rows.each do |_row|
      if @collection.is_parent != 1
        logger.debug("Find: " + @collection.name)
      else
        logger.debug("[OaiSearchClass][RetrieveOAI] CHECK: #{collection.id}  #{UtilFormat.normalize(_row.dc_identifier)}")
        _newset = @collection.alt_name
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

      if _tmp_max <= @max
        logger.debug("[OaiSearchClass][RetrieveOAI] Prepping to print Title, etc.")
        record = initialize_record_mapping(nil, _row)
        logger.debug("[OaiSearchClass][RetrieveOAI] Title: " + UtilFormat.normalize(_row.dc_title))
        logger.debug("[OaiSearchClass][RetrieveOAI] creator: " + UtilFormat.normalize(_row.dc_creator))
        logger.debug("[OaiSearchClass][RetrieveOAI] date: " + UtilFormat.normalizeDate(_row.dc_date))
        logger.debug("[OaiSearchClass][RetrieveOAI] description: " + UtilFormat.normalize(_row.dc_description))
        logger.debug("[OaiSearchClass][RetrieveOAI] SITE PREF: " + UtilFormat.normalize(_sitepref))
        logger.debug("[OaiSearchClass][RetrieveOAI] SITE URL: " + UtilFormat.normalize(@collection.url))
        
        harvesting_date = @date_indexed[_row['dc_identifier'].to_s]
        if (!harvesting_date.nil?)
          harvesting_date = DateTime.parse(harvesting_date)
        else
          harvesting_date = ""
        end
        record.date_indexed = harvesting_date

        begin
          record.rank = _objRec.calc_rank({'title'   => UtilFormat.normalize(_row.dc_title),
            'atitle'  => '',
            'theme'   => '', # UtilFormat.normalize(_row.theme),
            'creator' =>UtilFormat.normalize(_row.dc_creator),
            'date'    => _row.dc_date,
            'rec'     => UtilFormat.normalize(_row.dc_description),
            'pos'     =>1,
            'pref'    => _sitepref,
            'url'     => UtilFormat.normalize(@collection.url) },
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
        record.vendor_name = @collection.alt_name

        _tmp_type = UtilFormat.normalize(@collection.mat_type)
        if _row.dc_type != nil # and _row.dc_type.index(/[;\/\?\.]/) == nil
          _tmp_type = UtilFormat.normalize(_row.dc_type)
        end

        record.ptitle = UtilFormat.normalize(_row.dc_title)
        if UtilFormat.normalize(_tmp_type) == 'Article'
          record.title = ""
          record.atitle = UtilFormat.normalize(_row.dc_title)
        else
          record.title =  UtilFormat.normalize(_row.dc_title)
          record.atitle =  ""
        end
        logger.debug("record title: " + record.title)
        record.hits = @total_hits
        record.issn =  ""
        record.isbn = ""
        record.id = _row.dc_identifier.to_s + ID_SEPARATOR + @collection.id.to_s + ID_SEPARATOR + @search_id.to_s
        record.doi = ""
        record = set_record_access_link(record,@collection.host)
        record.availability = @collection.availability
        record.lang = UtilFormat.normalizeLang(UtilFormat.normalize(_row.dc_language))
        record.theme = "" # chkString(uniqString(_row.theme))
        record.vendor_url = @collection.vendor_url

        record.material_type = PrimaryDocumentType.getNameByDocumentType(_tmp_type, @collection.id)
        if record.material_type.blank?
          record.material_type = UtilFormat.normalize(@collection.mat_type)
        end
        record.vendor_name = @collection.alt_name
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.actions_allowed = @collection.actions_allowed
        record.issue_title = _row.dc_source

        @records[_x] = record
        _x = _x + 1
      end

      _oldset = _newset
      _count = _count + 1
      _tmp_max = _tmp_max + 1
    end

    logger.debug("Record Hits: #{@records.length} sur #{@total_hits}")

    return @records
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
