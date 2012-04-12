module SearchClassHelper
  def proxy?
    if @collection.proxy == 1
      @yp ||= YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
      @proxy_host ||= @yp['PROXY_HTTP_ADR']
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
      if row.respond_to?("#{key}".to_sym)
        record.instance_variable_set("@#{key}", row.send("#{key}".to_sym))
      elsif row.respond_to?("dc_#{key}".to_sym)
        record.instance_variable_set("@#{key}", row.send("dc_#{key}".to_sym))
      elsif row.respond_to?("osu_#{key}".to_sym)
        record.instance_variable_set("@#{key}", row.send("osu_#{key}".to_sym))
      elsif row.instance_variable_get("#{key}")
        record.instance_variable_set("@#{key}", row.instance_variable_get("#{key}"))
      elsif row.instance_variable_get("dc_#{key}")
        record.instance_variable_set("@#{key}", row.instance_variable_get("dc_#{key}"))
      elsif row.instance_variable_get("osu_#{key}")
        record.instance_variable_set("@#{key}", row.instance_variable_get("osu_#{key}"))
      elsif key == "author"
        record.instance_variable_set("@#{key}", row.instance_variable_get("dc_creator")) if row.instance_variables.include?("dc_creator")
        record.instance_variable_set("@#{key}", row.send(:dc_creator)) if row.respond_to?(:dc_creator)  
      elsif key == "abstract"
        record.instance_variable_set("@#{key}", row.instance_variable_get("dc_description")) if row.instance_variables.include?("dc_description")
        record.instance_variable_set("@#{key}", row.send(:dc_description)) if row.respond_to?(:dc_description)  
      else
        record.instance_variable_set("@#{key}","")
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
end