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

class ClassiquesGarnierSearchClass < ActionController::Base
  include SearchClassHelper
  # require 'ferret'
  attr_reader :hits, :xml
  attr_accessor :list_of_ids, :bfound
  @total_hits = 0
  @pid = 0
  @pkeyword = ""
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user=nil, options=nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)

    logger.debug("[#{self.class}] [SearchCollection]")
    _sTime = Time.now().to_f
    keyword(_qstring[0])
    @action = _action_type
    @options = options
    @collection = _collect
    @search_id = _last_id
    @infos_user = infos_user
    @max = _max.to_i
    @action = _action_type
    @records = []
    @query_string = _qstring
    @query_type = _qtype
    @operators = _qoperator

    search
    logger.debug("Storing found results in cached results begin")
    save_in_cache
  end

  def search
    _start_time = Time.now()
    record_set = RecordSet.new
    _hits = {}
    @date_indexed = {}
    @bfound = false
    keywords = @query_string.join("|")

    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      keywords = UtilFormat.normalizeFerretKeyword(keywords)
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      keywords = UtilFormat.normalizeSolrKeyword(keywords)
    end
    if keywords.slice(0,1) != "\""
      if keywords.index(' OR ').nil?
        keywords = keywords.gsub("\"", "'")
        #I think this is a problem.
        #_keywords = "\"" + _keywords + "\""
      end
    end
    
    @list_of_ids ||= solr_request
    return nil if !@list_of_ids
   
    _sTime = Time.now().to_f
    _results = Metadata.find(:all, :conditions=>{:dc_identifier=>@list_of_ids})
    @total_hits = _results.count
    _x = 0
    @records = []
    _i = 0
    options = {}
    _results.each do |_row|
      if _x <= @max
        logger.debug("Prepping to print Title, etc.")
        # set harvesting date
        harvesting_date = @date_indexed[_row['dc_identifier'].to_s]
        if (!harvesting_date.nil?)
          harvesting_date = DateTime.parse(harvesting_date)
        else
          harvesting_date = ""
        end
        options['date_indexed'] = harvesting_date
        # set rank
        rank = record_set.calc_rank({'title' => UtilFormat.normalize(_row.dc_title),
                'theme' => "",
                'atitle' => '',
                'creator'=>UtilFormat.normalize(_row.dc_creator),
                'date'=>UtilFormat.normalizeDate(_row.dc_date),
                'rec' => UtilFormat.normalize(_row.dc_description),
                'pos'=>1},
              @pkeyword)
        options['rank'] = rank
        options['vendor_name'] = UtilFormat.normalize(@collection.alt_name) 
        options['ptitle'] = UtilFormat.normalize(_row.dc_title)
        record = initialize_record_mapping(nil, _row, options)
        type = _row.dc_type
        if !type.nil? and UtilFormat.normalize(type.humanize) == 'Article'
          record.title = UtilFormat.normalize(_row.dc_publisher)
          record.atitle = UtilFormat.normalize(_row.dc_title)
        else
          record.title =  UtilFormat.normalize(_row.dc_title)
          record.atitle =  ""
        end
        record.id = UtilFormat.normalize(_row.dc_identifier) + ID_SEPARATOR +  @collection.id.to_s + ID_SEPARATOR + @search_id.to_s
        record = set_record_access_link(record, _row.osu_linking)
        record.static_url = @collection.host
        record.lang = UtilFormat.normalizeLang("fr")
        record.hits = @total_hits
        record.availability = @collection.availability
        record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(type), @collection.id)
        if record.material_type.blank?
          #record.material_type = UtilFormat.normalize(_type[@collection.id])
        end
        record.vendor_url = @collection.vendor_url
        record.page = UtilFormat.normalize(_row.osu_volume.to_s)
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.actions_allowed = @collection.actions_allowed
        @records[_x] = record
        _x += 1
      end
    end
    logger.debug("Record Hits: #{@records.length} sur #{@total_hits}")
    @records
  end

  def self.GetRecord(dc_identifier = nil, collection_id = nil, search_id = "", infos_user = nil)

    #logger.debug("[GetRecord] : idDoc = #{idDoc}")
    if collection_id == nil or dc_identifier == nil
      logger.debug "#{self.name} - Missing arguments to retrieve informations about the document"
      return nil
    end

    if search_id == 0
      search_id = ""
    end

    begin
      col = Collection.find(collection_id)
    rescue
      logger.error("Collection not found error")
      return nil
    end

    begin
      _results = Metadata.find(:one).where(:collection_id=>collection_id,:dc_identifier=>dc_identifier)
    rescue
      logger.error("Query collection name error")
      return nil
    end

    begin
      # Get the results

      _results.each do |_row|
        if _row.oai_identifier.to_s == dc_identifier.to_s
          record = initialize_record_mapping(nil, _row)
          record.ptitle = chkString(_row.dc_title)
          record.material_type = PrimaryDocumentType.getNameByDocumentType(chkString(_row.dc_type), _row.collection_id)
          if record.material_type.blank?
            record.material_type = UtilFormat.normalize(col.mat_type)
          end
          record.id = UtilFormat.normalize(_row.dc_identifier) + ID_SEPARATOR +  _row.collection_id.to_s + ID_SEPARATOR + search_id.to_s
          
          record = set_record_access_link(record, _row.osu_linking)
          record.vendor_name = chkString(_row.dc_source)
          record.vendor_url = chkString(col.host)
          record.availability = col.availability
          record.lang = UtilFormat.normalizeLang("fr")
          record.actions_allowed = col.actions_allowed
          return record
        end
      end
    rescue Exception => e
      logger.error("[ClassiquesgarnierSearch Class][GetRecord] No records matching")
      logger.error("[ClassiquesgarnierSearch Class][GetRecord] error #{e.message}")
      logger.debug("[ClassiquesgarnierSearch Class][GetRecord] stack #{e.backtrace}")
    end
    return nil
  end
  
end
