module SearchClassHelper
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
  
  def keyword (_string)
    @pkeyword = _string
  end
  
  def insert_id(_id) 
    @pid = _id
  end
  
  # check the state of variables
  def chkString(_str)
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
end