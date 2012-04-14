require 'solr'
module SearchClassHelper
  include Solr
  # perform a request in solr and return a list of ids
  def solr_request
    begin
      raw_query_string, opt = UtilFormat.generateRequestSolr(@query_type, @query_string, @operators, @collection.filter_query, @collection.is_parent, @collection, @collection.name, @max, @options)
      conn = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
      logger.info("[#{self.class}] [solr_request] RAW STRING: " + raw_query_string)
      response = conn.query(raw_query_string, opt)
      @total_hits = _response.total_hits
      response.each do |hit|
        next if !defined?(hit["controls_id"])
        list_of_ids << hit["controls_id"]
        @themes[hit["controls_id"].to_s] = hit["theme"] if @themes
        @date_end_new[hit["controls_id"].to_s] = hit["date_end_new"] if @date_end_new
        @date_indexed[hit["controls_id"].to_s] = hit["harvesting_date"]
        @bfound = true
      end
    rescue Exception => e
      logger.error("[#{self.class}] [solr_request] Error #{e.message}")
      logger.debug("[#{self.class}] [solr_request] Error #{e.backtrace}")
    end

    return list_of_ids
  end

  def proxy?
    if @collection.proxy == 1
      @yp ||= YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
      @proxy_host ||= @yp['PROXY_HTTP_ADR'].gsub("http://","")
      @proxy_port ||= @yp['PROXY_HTTP_PORT']
      return true
    else
      @proxy_host = nil
      @proxy_port = nil
      return false
    end
  end

  def save_in_cache
    @print = false
    if @records
      @json_records = CachedSearch.build_cache_xml(@records)
      @print = true if @json_records and !@records.empty?
      @json_records = @json_records ? @json_records : ""

      #============================================
      # Add this info into the cache database
      #============================================
      if !@search_id
        # FIXME:  Raise an error
        logger.error("Error: _last_id should not be nil")
      else
        logger.debug("#{self.class} - Save metadata")
        @status = LIBRARYFIND_CACHE_OK
        @status = LIBRARYFIND_CACHE_EMPTY if !@print
        @my_id = CachedSearch.save_metadata(@search_id, @json_records, @collection.id, @max.to_i, @status, @infos_user, @total_hits)
      end
    else
      logger.debug("#{self.class} save bad metadata")
      @json_records = ""
      @my_id = CachedSearch.save_metadata(@search_id, @json_records, @collection.id, @max.to_i, LIBRARYFIND_CACHE_EMPTY, @infos_user)
    end

    if @action
      if @records
        return @my_id, @records.length, @total_hits
      else
        return @my_id, 0, @total_hits
      end
    else
      return @records
    end
  end

  def set_record_access_link(record, link)
    if(INFOS_USER_CONTROL and !@infos_user.nil?)
      # Does user have rights to view the notice ?
      droits = ManageDroit.GetDroits(@infos_user,@collection.id)
      if(droits.id_perm == ACCESS_ALLOWED)
        record.direct_url = link
      else
        record.direct_url = ""
      end
    else
      record.direct_url = link
    end
    record
  end

  def initialize_record_mapping(record, row, key_value_pairs={})
    record = Record.new if !record

    record.instance_variables.each do |key|
      dc_key = "@dc_#{key[1..key.length]}"
      osu_key = "@dc_#{key[1..key.length]}"
      key_sym = "#{key[1..key.length]}".to_sym
      dc_key_sym = "dc_#{key[1..key.length]}".to_sym
      osu_key_sym = "osu_#{key[1..key.length]}".to_sym
      if row.respond_to?(key_sym)
        record.instance_variable_set("#{key}", row.send(key_sym))
      elsif row.respond_to?(dc_key_sym)
        record.instance_variable_set("#{key}", row.send(dc_key_sym))
      elsif row.respond_to?(osu_key_sym)
        record.instance_variable_set("#{key}", row.send(osu_key_sym))
      elsif row.instance_variables.include?("#{key}")
        record.instance_variable_set("#{key}", row.instance_variable_get("#{key}"))
      elsif row.instance_variables.include?(dc_key)
        record.instance_variable_set("#{key}", row.instance_variable_get(dc_key))
      elsif row.instance_variables.include?(osu_key)
        record.instance_variable_set("#{key}", row.instance_variable_get(osu_key))
      elsif key == :@author
        record.instance_variable_set("#{key}", row.instance_variable_get("@dc_creator")) if row.instance_variables.include?("@dc_creator")
        record.instance_variable_set("#{key}", row.send(:dc_creator)) if row.respond_to?(:dc_creator)
      elsif key == :@abstract
        record.instance_variable_set("#{key}", row.instance_variable_get("@dc_description")) if row.instance_variables.include?("@dc_description")
        record.instance_variable_set("#{key}", row.send(:dc_description)) if row.respond_to?(:dc_description)
      else
        record.instance_variable_set("#{key}","")
      end
    end
    key_value_pairs.each do |key, value|
      record.instance_variable_set("@#{key}", value)
    end
    record
  end

  def keyword (_string)
    @pkeyword = _string
  end

  def insert_id(_id)
    @pid = _id
  end

  # check the state of variables
  def chkString(_str)
    begin
      if _str.nil?
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

  def normalize(_string)
    return UtilFormat.normalize(_string) if _string
    return ""
  end

  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user=nil, options=nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)

    begin
      logger.debug("[PortfolioSearchClass] [SearchCollection]");
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

      logger.debug "[#{self.class}] [SearchCollection] Searching in #{@collection.name}"
      search
      logger.debug("[#{self.class}] [SearchCollection] Storing found results in cached results begin")
      return save_in_cache
    rescue => e
      logger.error("[#{self.class}][SearchCollection] Error : " + e.message)
      logger.error("[#{self.class}][SearchCollection] Trace : " + e.backtrace.join("\n"))
    end
  end
end