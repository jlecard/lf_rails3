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

class GedSearchClass < ActionController::Base
  include SearchClassHelper
  # require 'ferret'
  attr_reader :hits, :xml
  attr_accessor :list_of_ids

  @total_hits = 0
  @pid = 0
  @pkeyword = ""
  def search
    _x = 0
    _y = 0
    _oldset = ""
    _newset = ""
    _count = 0
    _tmp_max = 1
    _xml_tmp = ""
    _xml = ""
    _start_time = Time.now
    _objRec = RecordSet.new
    _hits = Hash.new()
    @date_end_new = {}
    @date_indexed = {}
    logger.debug("GED Search")

    _keywords = @query_string.join("|")
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
      index = Ferret::Search::Searcher.new(LIBRARYFIND_FERRET_PATH)
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
        _query << " C.oai_identifier='" + index[doc]["controls_id"].to_s + "' or "
        _bfound = true;

      end
      index.close

    elsif LIBRARYFIND_INDEXER.downcase == 'solr'

      logger.debug("Entering SOLR")
      @list_of_ids ||= solr_request
      return nil if !@list_of_ids
    end

    _sTime = Time.now().to_f
    _results = Metadata.find(:all, :conditions=>{:collection_id=>@collection.id,:dc_identifier=>@list_of_ids})
    @total_hits = _results.count

    if _results.empty?
      logger.warn("no result found: " + _coll_list.to_s)
      return nil
    end
    _i = 0
    _newset = ""
    _results.each do |_row|
      logger.debug("[GedSearchClass][RetrieveGED] row = #{_row.inspect}")
      if @collection.is_parent != 1
        logger.debug("Find: " + @collection.name)
      else
        logger.debug("[OaiSearchClass][RetrieveOAI] CHECK: #{collection.id}  #{UtilFormat.normalize(_row.oai_identifier)}")
        _newset = @collection.alt_name
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

      if _tmp_max <= @max
        logger.debug("Prepping to print Title, etc.")
        record = initialize_record_mapping(nil, _row)
        logger.debug("[GedSearchClass][RetrieveGED] Title: " + UtilFormat.normalize(_row.dc_title))
        logger.debug("[GedSearchClass][RetrieveGED] creator: " + UtilFormat.normalize(_row.dc_creator))
        logger.debug("[GedSearchClass][RetrieveGED] date: " + UtilFormat.normalizeDate(_row.dc_date))
        logger.debug("[GedSearchClass][RetrieveGED] description: " + UtilFormat.normalize(_row.dc_description))
        logger.debug("[GedSearchClass][RetrieveGED] publisher: " + UtilFormat.normalize(_row.dc_publisher))

        date_end_new = @date_end_new[_row['dc_identifier'].to_s]
        if (!date_end_new.nil?)
          date_end_new = DateTime.parse(date_end_new)
        else
          date_end_new = ""
        end
        record.date_end_new = date_end_new

        harvesting_date = @date_indexed[_row['dc_identifier'].to_s]
        if (!harvesting_date.nil?)
          harvesting_date = DateTime.parse(harvesting_date)
        else
          harvesting_date = ""
        end
        record.date_indexed = harvesting_date

        record.rank = _objRec.calc_rank({'title' => UtilFormat.normalize(_row.dc_title),
          'theme' => "",
          'atitle' => '',
          'creator'=>UtilFormat.normalize(_row.dc_creator),
          'date'=>UtilFormat.normalizeDate(_row.dc_date),
          'rec' => UtilFormat.normalize(_row.dc_description),
          'pos'=>1},
        @pkeyword)

        record.vendor_name = UtilFormat.normalize(@collection.alt_name)
        record.ptitle = UtilFormat.normalize(_row.dc_title)
        record.title = UtilFormat.normalize(_row.dc_title)
        record.atitle = UtilFormat.normalize(_row.dc_title)

        logger.debug("[GedSearchClass][RetrieveGED] record title: " + record.title)
        record.issn =  ""
        record.isbn = ""
        record.id = chkString(_row.dc_identifier) + ID_SEPARATOR + @collection.id.to_s + ID_SEPARATOR  + @search_id.to_s
        record.doi = ""
        link_ref = transalteUnidEtDonsToUrlGed(record.identifier)
        # Does user have rights to view the notice ?
        record = set_record_access_link(record, link_ref)
        record.direct_url = _row.oai_identifier if !record.direct_url
        record.lang = UtilFormat.normalizeLang("fr")
        record.hits = @total_hits
        record.ptitle = UtilFormat.normalize(_row.dc_title)
        if !row.dc_type or !row.dc_type.empty?
          record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(@collection.mat_type), _row.collection_id)
        else
          record.material_type
        end

        record.vendor_url = @collection.vendor_url
        record.page = UtilFormat.normalize(_row.osu_volume.to_s)
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.issue_title = _row.dc_publisher

        record.actions_allowed = @collection.actions_allowed

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
    ### TODO: replace by CachedSearchClass method ???
    if idDoc == nil or idCollection == nil
      logger.debug "-ged search class-Missing arguments to retrieve informations about the document"
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
          record.title =  ""
          record.author = chkString(_row.dc_creator)
          record.subject = chkString(_row.dc_subject)
          record.abstract = chkString(_row.dc_description)
          record.publisher = chkString(_row.dc_publisher)
          record.contributor = chkString(_row.dc_contributor)
          record.date = UtilFormat.normalizeDate(_row.dc_date)
          record.material_type = PrimaryDocumentType.getNameByDocumentType(chkString(_row.dc_type), _row.collection_id)
          if record.material_type.blank?
            record.material_type = UtilFormat.normalize(col.mat_type)
          end
          record.format = chkString(_row.dc_format)
          record.id = chkString(_row.oai_identifier) + ID_SEPARATOR + _row.collection_id.to_s + ID_SEPARATOR  + idSearch.to_s
          record.source = ""
          record.relation = chkString(_row.dc_relation)
          record.coverage = chkString(_row.dc_coverage)
          record.rights = chkString(_row.dc_rights)
          #          record.link = chkString(_row.osu_linking)
          record.openurl = chkString(_row.osu_openurl)
          record.thumbnail_url = chkString(_row.osu_thumbnail)
          record.volume = chkString(_row.osu_volume)
          record.issue = chkString(_row.osu_issue)
          record.identifier = chkString(_row.oai_identifier)

          record.theme = "" # chkString(uniqString(_row.theme))
          record.category = ""
          record.issn =  ""
          record.isbn = ""
          record.doi = ""
          record.issue_title = _row.dc_publisher
          # Does user have rights to view the notice ?
          if(INFOS_USER_CONTROL and !infos_user.nil?)
            droits = ManageDroit.GetDroits(infos_user,_row.collection_id)
            if(droits.id_perm == ACCESS_ALLOWED)
              record.direct_url = transalteUnidEtDonsToUrlGed(record.identifier)
              record.availability = col.availability
            else
              record.availability = ""
              record.direct_url = "";
            end
          else
            record.direct_url = _row.oai_identifier
            record.availability = col.availability
          end
          record.static_url = ""
          record.callnum = ""
          record.page = ""
          record.number = ""
          record.rank = ""
          record.hits = ""
          record.atitle = ""
          record.vendor_name = col.alt_name
          record.vendor_url = col.vendor_url
          record.start = ""
          record.end = ""
          record.holdings = ""
          record.raw_citation = ""
          record.oclc_num = ""
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

  def transalteUnidEtDonsToUrlGed(nuid=nil, dons=nil)
    if nuid==nil
      logger.warn("[transalteUnidToUrlGed] nuidEtDons is nil")
    else
      begin
        if dons==nil
          dons = GED_NAME_FILE
        end
        logger.debug("[transalteUnidToUrlGed] nuidEtDons is " + nuid + " and dons=" + dons)
        _hexa = nuid.to_i.to_s(16)
        logger.debug("[transalteUnidToUrlGed] code hexa is " + _hexa)
        _diff = GED_NB_CAR_REP.to_i - _hexa.to_s.length
        logger.debug("[transalteUnidToUrlGed] diff = " + _diff.to_s)

        if (_diff >= 0)

          _diff.times { |i|
            _hexa = "0" + _hexa.to_s
          }
          logger.debug("[transalteUnidToUrlGed] code hexa is " + _hexa.to_s)
          _pathDocument = ""
          i = 1
          _hexa.to_s.each_char { |car|
            _pathDocument = _pathDocument + car

            if i%2 == 0
              _pathDocument = _pathDocument + GED_URL_SEPARATOR
            end
            i = i + 1
          }
          _url = ""
          logger.debug("[transalteUnidToUrlGed] code _pathDocument is " + _pathDocument.to_s)
          _url = GED_URL_PATH + _pathDocument + dons
          logger.debug("[transalteUnidToUrlGed] url final is " + _url.to_s)
          return _url
        else
          logger.error("[transalteUnidToUrlGed] the difference is negative, see the variable GED_NB_CAR_REP [hexa:" + _hexa + " GED_NB_CAR_REP:" + GED_NB_CAR_REP + "]")
        end
      rescue
        logger.error("Error in transalteUnidEtDonsToUrlGed #{$!}")
      end
    end
    return nil
  end

end
