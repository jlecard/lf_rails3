# $Id: MetaSearch.rb 386 2006-09-01 23:34:07Z dchud $

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

require 'monitor'
require 'spawn'
require 'solr'
require 'solr/request/spellcheck.rb'
require 'solr/response/spellcheck.rb'

class MetaSearch < ActionController::Base
  #========================================================
  #_sets is a hash -- format passed should be
  # :set => 'oasis;aph',
  # :group => 'image'
  # _query == value returned from using the 
  # _params = hash containing info
  # :start => 0
  # :max => 10
  # :force_reload => 1 (to force reload)
  # :session => 'session number' (only present if needed)
  #=========================================================
  def initialize
    super
    logger.info("[MetaSearch][initialize]")
    @infos_user = nil
  end
  
  def simple_search(_sets, _qtype, _qstring, _start, _max)
    case _qtype.class.to_s
      when "Array"
      return Search(_sets, _qtype, _qstring, _start, _max, nil,nil,nil,true)
    else
      qtype = Array.new
      qstring = Array.new
      qtype[0] = _qtype
      qstring[0] = _qstring
      return Search(_sets, qtype, qstring, _start, _max, nil, nil, nil, true)
    end
  end
  
  def simple_search_async(_sets, _qtype, _qstring, _start, _max)
    case _qtype.class.to_s
      when "Array"
      return search_async(_sets, _qtype, _qstring, _start, _max, 1,nil,nil,true)
    else
      qtype = Array.new
      qstring = Array.new
      qtype[0] = _qtype
      qstring[0] = _qstring
      return search_async(_sets, qtype, qstring, _start, _max, 1, nil, nil, true)
    end
  end
  
  
  def Search(_sets, _qtype, _qstring, _start, _max, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    record = Array.new()
    _zoom = nil
    _objRec = RecordSet.new
    _objRec.setKeyword( _qstring[0])
    _stype = _qtype[0]
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    #_dbh = Mysql.real_connect(config['host'], config['username'], config['password'], 
    #config['database'])
    #config['database'], config['port'], nil, nil)
    _tmp = ""
    _max_recs = 0
    
    if _max == nil 
      _max = 10
    end
    
    _collections = Collection.find_resources(_sets)
    _query = ""       
    #================================================
    # Check the cache
    #================================================
    _search_id = nil
    # Has this search been run before?  Return the matching row as array if so 
    logger.info("[Search] IS THIS FIXED: " + _qstring[0].to_s)
    logger.info("[Search] STILL Correct: " + _qstring.join(" "))
    _last_id, _max_recs = CachedSearch.check_cache(_qstring, _qtype, '', _max, @infos_user)

    if CACHE_ACTIVATE
      if _search_id.nil?
        logger.info("[meta_search][Search] setting cache for query")
        _last_id, _max_recs = CachedSearch.set_query(_qstring, _qtype, '', _max.to_i, @infos_user)
      else
        _search_id = _last_id
      end
    else
      if _last_id.length==0
      # _last_id is generated when this search is saved
        logger.info("No matching search found")
        _last_id = CachedSearch.set_query(_qstring, _qtype, '', _max.to_i, @infos_user)
      else
      # _last_id is the id of the matching search
        _last_id = cached_recs[0].id
        logger.info("[Search] Matching search: %s" % _last_id)
      # _search_id starts with same id, but is modified later
        _search_id = cached_recs[0].id
      # _max_recs is the saved number of hits per collection 
      # (which might be insufficient)
        _max_recs = cached_recs[0].max_recs
        logger.info("[Search] max hits: " + _max_recs.to_s)
      end
    end
    $lthreads = []
    
    objAuth = Authorize.new 
    _collections.each do |_collect|
      if _collect['is_private'] == 1
        next
      end
      #================================================
      # If in Cache -- extract data from the cache
      # and return
      #================================================
      _lrecord = Array.new()
      is_in_cache = false
      #======================================================
      # Check to see if data was cached -- if it is load
      #======================================================
      # NOTE: only runs for matched searches
      if _search_id != nil
        _lxml = CachedSearch.retrieve_metadata(_search_id, _collect.id, _max.to_i, @infos_user)
        logger.info("[Search] found in cache")
        if _lxml != nil
          logger.info("[meta_search][Search] cached search xml return object = #{_lxml.class}")
          is_in_cache = true    
          if _lxml.status == LIBRARYFIND_CACHE_OK
            # Note:  it should never happen that .data is nil
            if _lxml.data != nil
              # Load from cache
              _lrecord =  _objRec.unpack_cache(_lxml.data, _max.to_i) 
              record.concat(_lrecord)
            end
          else
            if _lxml.status == LIBRARYFIND_CACHE_ERROR
              is_in_cache=false
            end
          end
        else
          logger.info("Didn't find cached records")
        end
      end
      job_id = -1
      logger.info("[Search] QUERYSTRING1: " + _qstring.join(" ") + _collect.conn_type) 
      if is_in_cache == false
        if _collect.conn_type == "oai"
          begin
            #The reason we have to do this is because of ferret.  I'm 
            #not sure why -- but I'm having all kinds of trouble with 
            #ferret causing trouble in a threaded environment.
            _tmparray = Array.new()
            _start_thread = Time.now().to_f
            logger.info("[Search] QUERYSTRING: " + _qstring.join(" "))
            eval("_tmparray = #{_collect.conn_type.capitalize}SearchClass.SearchCollection(_collect, _qtype, _qstring, _start.to_i, _max.to_i, _last_id, job_id, @infos_user, options, _session_id, _action_type, _data, _bool_obj)")
            _end_thread =  Time.now().to_f - _start_thread
            CachedSearch.save_execution_time(_last_id, _collect.id, _end_thread.to_s, @infos_user)
            if _tmparray != nil 
              record.concat(_tmparray) end
          rescue
            logger.info("Error generating oai search class")
          end
        else
          begin
            if _qstring.join(" ").index("site:") != nil
              # we skip because this is only present for harvested materials
              next
            end
            _qstringtemp = pNormalizeString(_qstring)
            logger.info("[Search] not oai, starting thread")
            $lthreads << Thread.new(_collect) do |_coll|
              Thread.current["myrecord"] = Array.new()
              Thread.current["mycount"] = 0
              
              _tmparray = Array.new()
              _start_thread = Time.now().to_f
              if _coll.conn_type != 'connector'
                eval("_tmparray = #{_coll.conn_type.capitalize}SearchClass.SearchCollection(_coll, _qtype, _qstringtemp, _start.to_i, _max.to_i, _last_id, job_id, @infos_user, options, _session_id, _action_type, _data, _bool_obj)")
              else
                eval("_tmparray = #{_coll.oai_set.capitalize}SearchClass.SearchCollection(_coll, _qtype, _qstringtemp, _start.to_i, _max.to_i, _last_id, job_id, @infos_user, options, _session_id, _action_type, _data, _bool_obj)")
              end
              _end_thread =  Time.now().to_f - _start_thread
              CachedSearch.save_execution_time(_last_id, _coll.id, _end_thread.to_s, @infos_user) 
              if _tmparray != nil
                Thread.current["myrecord"].concat(_tmparray)
                Thread.current["mycount"] = _tmparray.length
              end
            end
          rescue
            logger.error("[Search] Error generating other searchclasses")
          end
        end
      end
    end
    
    $lthreads.each {|_thread| 
      begin
        _thread.join(300)
        if _thread["mycount"] != 0
          record.concat(_thread["myrecord"])
        end
        #rescue RuntimeError => e
        #  logger.info(e.to_s)
      rescue
        next
      end
    } 
    $lthreads = nil
    
    CachedSearch.save_hits(_last_id, _session_id, record.size, _action_type, _data)
    if _bool_obj==false
      return _tmp
    else
      record.sort!{|a,b| b.rank.to_f <=> a.rank.to_f}
      #if record.length > (_max.to_i * 4)
      #  return record.slice(0,(_max.to_i*4))           
      #else
      return record
      #end
    end
  end
  
  
  # _sets :         query_sets (collection_groups)
  # _qtype:       table (creator, title, ...)
  # _qstring :    table of keywords (string1, string2, string3)
  # _start :        begin search by 0 (DEFAULT) or _start
  # _max :          max result by search
  # _qoperator :  table of operators (operator1, operator2)
  def search_async (_sets, _qtype, _qstring, _start, _max, _qoperator, options=nil, _session_id=nil, _action_type=1, _data = nil, _bool_obj=true) 
    logger.info("[search_async] INFOS_USER_CONTROL : #{INFOS_USER_CONTROL} @infos_user : #{@infos_user.inspect}")
    logger.info("[search_async] spawn method found in #{2.method(:spawn)}")
    if(INFOS_USER_CONTROL and !@infos_user.nil?)
      
      # Get collections list in which the user is authorized to search
      collections_permissions = ManageDroit.GetCollectionsAndPermissions(@infos_user)
      
      cols_ids_authorized = Collection.getCollectionsIds(collections_permissions)
    end
    
    _sTime = Time.now().to_f
    
    _objRec = RecordSet.new
    logger.info("[search_async] keyword:#{_qstring[0]}")
    logger.info("[search_async] keyword:#{_qstring.inspect}")
    _objRec.setKeyword( _qstring[0])
    _max_recs = 0
    
    # set max by collection if it's not set
    if _max == nil 
      _max = MAX_COLLECTION_SEARCH
    end
    
    # search collection for the set id
    logger.info("[search_async] search collection #{_sets.to_s}")
    no_externe = false
    if (!options.nil?)
      no_externe = true
    end
    _collections = Collection.find_resources(_sets, no_externe)
    
    logger.info("[search_async] collections #{_collections}")
    
    #================================================
    # Check the cache
    #================================================
    _search_id = nil
    _my_search_id = nil
    # Has this search been run before?  Return the matching row as array if so 
    logger.info("[search_async] IS THIS FIXED: " + _qstring.join("|").to_s)
    
    cached_recs, _max_recs = CachedSearch.check_cache(_qstring, _qtype,'', _max, @infos_user )
    
    if cached_recs.nil? || cached_recs.empty?
      # _last_id is generated when this search is saved
      logger.info("[search_async] No matching search found")
      _last_id, _max_recs = CachedSearch.set_query(_qstring, _qtype, '', _max.to_i, @infos_user)
    else
      
      if CACHE_ACTIVATE
        logger.info("[search_async] Matching search found...")
        _search_id = cached_recs  
        _last_id = cached_recs
      else
        # _last_id is the id of the matching search
        _last_id = cached_recs[0].id
        logger.info("[search_async] Matching search: #{ _last_id}")
        # _search_id starts with same id, but is modified later
        _search_id = cached_recs[0].id
        # _max_recs is the saved number of hits per collection 
        # (which might be insufficient)
        _max_recs = cached_recs[0].max_recs
      end
      logger.info("[search_async] max hits: " + _max_recs.to_s)
    end
    
    spawn_ids = []
    myjob = []
    _objCache = []
    qstring, qtype, qoperator = expand_query_with_synonyms(_qstring, _qtype)
    _qstring += qstring
    _qtype += qtype 
    _qoperator += qoperator 
    logger.info("[search_async] search_async _qstring : #{_qstring.inspect}")
    _collections.each_index { |_index|
      #================================================
      # If in Cache -- extract data from the cache
      # and return
      #================================================
      if _collections[_index] == nil
        next
      end
      
      # test si collection is private
      _is_private = false
      
      if(INFOS_USER_CONTROL and !@infos_user.nil?)
        if !cols_ids_authorized.include?(_collections[_index].id) or _collections[_index]['is_private'] == 1
          _is_private = true
        end
      end
      
      job_id = JobQueue.create_job(_collections[_index].id, 0, 0, _collections[_index].alt_name)
      if (!job_id.nil?)
        logger.info("[search_async] create job ; #{_collections[_index].id} ==> #{job_id}")
        myjob[_index] = job_id
      else
        logger.error("[search_async] #{_collections[_index].id} ==> job id nil")
        next
      end
      logger.info("[search_async] call spawn")
      
      spawn_ids[_index] = spawn_block do
        ActiveRecord::Base.establish_connection
        ############################################################################
        _pre_filtered_search = false
        _myqstring = Array.new(_qstring)
        #Adding the ability to filter query by collection
        if !_collections[_index].filter_query.blank?
          _myqstring << _collections[_index].filter_query
          _pre_filtered_search = true
        end   
        
        if !options.nil? and options.size > 2 and !options["query"].blank?
          _pre_filtered_search = true
          _myqstring << options["query"]
        end
        
        if _pre_filtered_search 
          logger.info("[search_async] Entering in pre filtered search mode")
          _my_search_id, my_cached_recs = CachedSearch.check_cache(_myqstring, _qtype,  '', _max, @infos_user)
          
          if my_cached_recs.nil? #or my_cached_recs.length==0 
            _my_last_id = CachedSearch.set_query(_myqstring, _qtype, '', _max.to_i, @infos_user)
          else
            if CACHE_ACTIVATE
              _my_last_id = _my_search_id
              _my_max_recs = my_cached_recs
              logger.info("[meta_search][search_async] cacheinfo : _my_last_id=#{_my_last_id}; _my_max_recs=#{_my_max_recs}")
            else
              _my_last_id = my_cached_recs[0].id
              _my_search_id = my_cached_recs[0].id
              _my_max_recs = my_cached_recs[0].max_recs
            end
          end
        end
        
        ############################################################################
        
        if !INFOS_USER_CONTROL or @infos_user.nil? or (INFOS_USER_CONTROL and cols_ids_authorized.include?(_collections[_index].id))
          logger.info("[search_async] Updating job")
          JobQueue.update_job(myjob[_index], nil, _collections[_index].alt_name, JOB_WAITING)	
          _objCache[_index] = CacheSearchClass.new()
          
          ############################################################################
          # Create a new search cache for the prefiltered search query
          ############################################################################
          if _pre_filtered_search
            logger.info("[search_async] Searching in pre filtered database cache")
            _s_id = _my_search_id
          else
            logger.info("[search_async] Searching in normal database")
            _s_id = _search_id
          end
          
          cache = true
          if (!options.nil?)
            cache = false
          else
            _objCache[_index].SearchCollection(_objRec, _collections[_index].id, _s_id, _max.to_i, myjob[_index], @infos_user,options)
          end
          ############################################################################
          logger.info("[search_async] Spawn ID: " + spawn_ids[_index].to_s)
          logger.info("[search_async] IS IN CACHE: " + _objCache[_index].is_in_cache.to_s) 
          
          if cache && _objCache[_index].is_in_cache == true  && _objCache[_index].records != nil
            
            logger.info("[search_async] spawn process to found in thread : " + myjob[_index].to_s)
            # need to mark query as finished.
            _job_etat = JOB_FINISHED
            if _is_private == true
              _job_etat = JOB_PRIVATE
            end
            if !_objCache[_index].records.empty?
              h = _objCache[_index].records[0].hits
            else
              h = 0
            end
            JobQueue.update_job(myjob[_index],_objCache[_index].records_id,  _collections[_index].alt_name, _job_etat, _objCache[_index].records.length, h)
            
          elsif cache && _objCache[_index].is_in_cache == true && _objCache[_index].records == nil
            # no records were found in the search -- results are zero
            logger.info("[search_async] result in cache but results are zero")
            JobQueue.update_job(myjob[_index], _objCache[_index].records_id, _collections[_index].alt_name, JOB_FINISHED, 0)
          else
            # no cache, so search now
            # No matching search found  
            begin
              logger.info("[search_async] start time")
              _start_thread = Time.now().to_f
              my_id = 0
              my_hits = 0
              total_hits = 0
              
              # Why this test ? i don't know
              if _qstring.join(" ").index("site:") != nil and _collections[_index].conn_type != 'oai'
                tmpreturn = JobQueue.update_job(myjob[_index], my_id, _collections[_index].alt_name, JOB_FINISHED, 0) 
                next
              end
              
              # change id if filter search
              _s_id = _last_id
              if _pre_filtered_search
                _s_id = _my_last_id
              end
              
              # normalize string if not oai et connector
              _q = _qstring
              if _collections[_index].conn_type != 'oai' and _collections[_index].conn_type != 'connector'
                _q = pNormalizeString(_qstring)
              end
              
              
              logger.info("[search_async] _q.inspect = #{_q.inspect}")
              
              # determine search class (using oai_set field info if connection type = connector (custom connector)
              _search_class = _collections[_index].conn_type.capitalize
              if _collections[_index].conn_type == 'connector'
                _search_class = _collections[_index].oai_set.capitalize
              end
              
              logger.info("[search_async] INDEXER: " + LIBRARYFIND_INDEXER)
              logger.info("[MetaSearch][search_async] - Query string: " + _q.join(" "))
              logger.info("[METASEARCH] : Search class = #{_search_class}")
              rescued = false
              begin
                eval("my_id, my_hits, total_hits = #{_search_class}SearchClass.SearchCollection(_collections[_index], _qtype, _q, _start.to_i, _max.to_i, _qoperator, _s_id, myjob[_index], @infos_user, options, _session_id, 1, _data, _bool_obj)")                
              rescue => e
                logger.error("[METASEARCH] : Search class = #{e.message}")
                logger.error("[METASEARCH] backtrace = #{e.backtrace}")
                raise e
              end
              # set finish time
              _end_thread =  Time.now().to_f - _start_thread
              CachedSearch.save_execution_time(_s_id, _collections[_index].id, _end_thread.to_s, @infos_user)
              
              logger.info("[search_async] My_ID = #{my_id.to_s} for collection #{_collections[_index]}")
              if my_id != nil
                # Set the job id message for finished.
                logger.info("[search_async] Updating status: " + " jobid: " + myjob[_index].to_s + " myid: " + my_id.to_s)
                _job_etat = JOB_FINISHED
                if _is_private == true
                  _job_etat = JOB_PRIVATE
                end
                if ((total_hits.to_i < my_hits.to_i) or (total_hits.to_i < _max.to_i) or (total_hits.to_i > _max.to_i and my_hits.to_i != _max.to_i))
                  total_hits = my_hits
                end
                tmpreturn = JobQueue.update_job(myjob[_index], my_id, _collections[_index].alt_name, _job_etat, my_hits, total_hits)
                logger.info("[search_async] return value from update: " + tmpreturn.to_s)
              else
                # Set the job id message for error; 
                logger.error("[search_async] Unable to establish/maintain a connection to the resource #{_collections[_index].alt_name}")
                JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, JOB_ERROR, -1, 0, "Unable to establish/maintain a connection to the resource")
              end 
              
            rescue ArgumentError => er
              logger.error("[search_async] error :" + er.message)
              JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, JOB_ERROR_TYPE, -1, 0, er.message)
            rescue Exception => bang
              logger.error("[search_async] error :" + bang.message)
              logger.error("[search_async] " + bang.backtrace.join("\n"))
              JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, JOB_ERROR, -1, 0, bang.message)
            end
          end
        else
          # case collection no rigth to search
          JobQueue.update_job(myjob[_index], nil, _collections[_index].alt_name, JOB_PRIVATE, -1, 0, "No right for this base")
        end
        
      end
      # Update the thread_ids to the job
      #
      ActiveRecord::Base.establish_connection
      logger.info("[search_async] job id: " + myjob[_index].to_s)
      logger.info("[search_async] spawn handle id: " + spawn_ids[_index].handle.to_s)
      logger.info("[search_async] spawn id: " + spawn_ids[_index].to_s)
      logger.info("[search_async] index: " + _index.to_s)
      JobQueue.update_thread_id(myjob[_index], spawn_ids[_index].handle)
    }
    logger.info("[search_async] finish")
    logger.warn("#STAT# [RETRIEVE] search_async " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
    return myjob
  end
  
  def expand_query_with_synonyms(_query, _qtype)
    logger.info("SOLR HOST = #{LIBRARYFIND_SOLR_HOST}")
    conn = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
    synonyms = Array.new 
    types = Array.new
    operators = Array.new
    idx = 0
    begin
      _query.each do |term|
        response = conn.query("searcher:(#{UtilFormat.normalizeSolrKeyword(term)})")
        logger.info("[MetaSearch][expand_query_with_synonyms] response #{response.inspect}")
        response.each do |row|
          row["searcher"].each do |item|
            logger.info("[MetaSearch][expand_query_with_synonyms] item added #{_qtype[idx]}:#{item}")
            synonyms.push(item.chomp)
            types.push(_qtype[idx])
            operators.push("OR")
          end
        end
        idx += 1
      end
    rescue => e
      logger.error("[MetaSearch][expand_query_with_synonyms] Error " + e.message)
    end
    return synonyms, types, operators
  end
  
  # pass a list of job ids and 
  # then deal with it
  def check_job_status(_ids)
    objJobs = [] 
    i = 0
    case _ids.class.to_s
      when "Array"
        results = JobQueue.check_status(_ids)
        if !results.nil?
          results.each do |tmpobj|
            if !tmpobj.nil?
      	      if (tmpobj.hits > tmpobj.total_hits and tmpobj.status == JOB_FINISHED)
                tmpobj.hits = tmpobj.total_hits
                tmpobj.save
	            end
            end
          end
        end
      return results
    else
      tmpobj = JobQueue.check_status(_ids)
      logger.info("[CHECKJOBSTATUS] Classe tmpobj = #{tmpobj.class.to_s}")
      if !tmpobj.nil?
        return tmpobj
      end
    end
    
  end
  
  # Retrieve the individual job records.
  # this basically is just an extraction from the cache
  def GetJobRecord(job_id,  _max)
    logger.info("[meta_search][GetJobRecord] get job record id #{job_id}")
    _objRec = RecordSet.new
    _xml = JobQueue.retrieve_metadata(job_id, _max, '', @infos_user)
    logger.info("[meta_search][GetJobRecord] cached search xml return object = #{_xml.class}")
    if _xml != nil
      if _xml.status == LIBRARYFIND_CACHE_OK
        # Note:  it should never happen that .data is nil
        if _xml.data != nil
          return _objRec.unpack_cache(_xml.data, _max.to_i)
        end
      end
    end
    return nil
  end 
  
  def KillThread(job_ids, thread_id = nil)
    if thread_id.nil?
      logger.info("[MetaSearch][KillThread] killing jobs #{job_ids}")
      job_ids.each do |job_id|
        begin
          job = JobQueue.find_by_id(job_id)
          logger.info("[MetaSearch][KillThread] job thread #{job.thread_id}")
          if (job.thread_id.to_i > 0) 
            JobQueue.transaction do 
              Process.kill("KILL", job.thread_id)
            end
          end
        rescue Exception => e
          logger.error("[MetaSearch][KillThread] error #{e.message}")
        ensure
          logger.error("[MetaSearch][KillThread] updating job #{job_id}")
          JobQueue.update_job(job_id, 0, nil, -3, 0, 0)
          return 0
        end
      end
    elsif (thread_id.to_i > 0) 
      JobQueue.transaction do 
		JobQueue.update_job(job_ids, 0, nil, -3, 0, 0)
        Process.kill("KILL", thread_id)
      end
    end
  end 
  
  def GetJobsRecords(job_ids, _max, temps)
    
    _sTime = Time.now().to_f
    _recs = Array.new();
    _tmp = Array.new();
    _objRec = RecordSet.new
    _rec = Record.new
    job_ids.each do |_id|
      # verification si dans le temps
      objJob = JobQueue.getJobInTemps(_id, temps)
      if (objJob.nil?)
        next
      end
      
      if CACHE_ACTIVATE
        tmp = nil
        if @infos_user and !@infos_user.location_user.blank?
          cle = "#{_id}_#{@infos_user.location_user}"
        else
          cle = "#{_id}"
        end
        begin
          tmp = CACHE.get(cle)
          if !tmp.blank?
            logger.info("[GetJobsRecords] got data from cache with key: #{cle}")
            _recs.concat(tmp)
            next
          end
        rescue => e
          logger.error("[GetJobsRecords] Error when get memcache: #{cle}: #{e.message}")
        end
      end
      
      _xml = JobQueue.retrieve_metadata(_id, _max, temps, @infos_user)
      logger.info("[meta_search][GetJobsRecord] cached search xml return object = #{_xml.class}")
      if _xml != nil
        if _xml.status == LIBRARYFIND_CACHE_OK
          # Note:  it should never happen that .data is nil
          if _xml.data != nil
            #logger.info("XML to UNPACK: " + _xml.data)
            # Load from cache
            _tmp =  _objRec.unpack_cache(_xml.data, _max.to_i)
            
            if _tmp != nil
              if CACHE_ACTIVATE
                logger.info("[GetJobsRecords] Set in cache with key = #{cle}")
                begin
                  CACHE.set(cle, _tmp, 3600.seconds)
                rescue
                  logger.error("[GetJobsRecords] error when writing in cache")
                end
              end
              _recs.concat(_tmp)
            end
          end
        end
      end
    end
    
    logger.info("#STAT# [GETRECORDS] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    return _recs;
  end
  
  def GetTotalHitsByJobs(jobs_ids)
    return JobQueue.total_hits_by_jobs(jobs_ids)
  end
  
  def ListCollections()
    objList = []
    objCollections = Collection.get_all()
    objCollections.each do |item|
      objCollectionList = CollectionList.new()
      objCollectionList.id = "c" + item.id.to_s
      objCollectionList.name = item.alt_name
      objMembers = CollectionGroup.get_parents(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "g" + coll.collection_group_id.to_s
        tmpvals = CollectionGroup.get_item(coll.collection_group_id)
        if tmpvals != nil
          arrNames << tmpvals
        else
          arrNames << "[undefined]"
        end
      end
      objCollectionList.member_ids = arrIds
      objCollectionList.member_names = arrNames
      objList << objCollectionList  
    end   
    return objList
  end
  
  def ListGroups(bool_advanced=false)
    objList = []
    objGroups = CollectionGroup.get_all(bool_advanced)
    objGroups.each do |item|
      objGroupList = GroupList.new()
      objGroupList.id = "g" + item.id.to_s
      objGroupList.name = item.full_name
      objMembers = CollectionGroup.get_members(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "c" + coll.collection_id.to_s
        tmpvals = Collection.get_item(coll.collection_id)
        if tmpvals != nil
          arrNames << Collection.get_item(coll.collection_id)
        else
          arrNames << "[undefined]"
        end 
      end
      objGroupList.member_ids = arrIds
      objGroupList.member_names = arrNames
      objList << objGroupList
      objGroupList.id_tab = item.tab_id
      objGroupList.description = item.description
    end 
    return (objList);
  end
  
  def GetGroupMembers(name)
    objGroupList = GroupList.new()
    objGroups = CollectionGroup.get_item_by_name(name)
    objGroups.each do |item|
      objGroupList.id = "g" + item.id.to_s
      objGroupList.name = item.full_name
      objMembers = CollectionGroup.get_members(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "c" + coll.collection_id.to_s
        tmpvals = Collection.get_item(coll.collection_id)
        if tmpvals != nil
          arrNames << Collection.get_item(coll.collection_id)
        else
          arrNames << "[undefined]"
        end 
      end
      objGroupList.member_ids = arrIds
      objGroupList.member_names = arrNames
    end
    return objGroupList
  end
  
  def GetId(id, logs = {})
    logger.info("[MetaSearch][GetId] id: #{id}")
    if id.blank?
      return nil
    end
    arr = id.split(";")
    
    begin
      _doc = MetaDisplay.new
      _r = _doc.display(arr[0], arr[1], arr[2], @infos_user)
      if !_r.nil?
        _r.id = id
        @log_management.logs(logs, _r)          
        return _r
      end
      
    rescue => err
      logger.error("[MetaSearch] [GetId] error: #{err.message}")
      logger.error("[MetaSearch] [GetId] error: #{err.backtrace.join('\n')}")
    end
    
    return nil 
  end
  
  def pNormalizeString(_qstring)
    _tqstring = Array.new(_qstring)
    _tmpsite = ""
    i = 0
    while i != _tqstring.length
      if _tqstring[i].index("site:")!= nil
        _tmpsite = _tqstring[i].slice(_tqstring[i].index("site:"), _tqstring[i].length - _tqstring[i].index("site:")).gsub("site:", "")
        _tqstring[i] = _tqstring[i].slice(0, _tqstring[i].index("site:")).chop
        if _tmpsite.index('"') != nil
          _tqstring[i] << '"'
        end
      elsif _tqstring[i].index("sitepref:") != nil
        _tmpsite = _tqstring[i].slice(_tqstring[i].index("sitepref:"), _tqstring[i].length - _tqstring[i].index("sitepref:")).gsub("sitepref:","")
        _tqstring[i] = _tqstring[i].slice(0, _tqstring[i].index("sitepref:")).chop
        if _tmpsite.index('"') != nil
          _tqstring[i] << '"'
        end
      end 
      i = i+1
    end
    logger.info("[MetaSearch][pNormalizeString] - string = #{_tqstring.inspect}")
    return _tqstring
  end
  
  def GetTabs()
    objList      = []
    objTabsList  = SearchTab.find(:all);
    
    objTabsList.each do |item|
      objTabList       = TabList.new();
      objTabList.id    = item.id;
      objTabList.name  = item.label;
      objTabList.description = item.description;
      
      objList << objTabList;
    end
    return objList;
  end
  
  def GetFilter()
    objList         = []
    objFiltersList  = SearchTabFilter.find(:all);
    
    objFiltersList.each do |item|
      objFilterList              = FilterList.new();
      objFilterList.id_tab       = item.search_tab_id;
      objFilterList.name         = item.label;
      objFilterList.filter       = item.field_filter;
      objFilterList.description  = item.description;
      objFilterList.id           = item.id
      objList << objFilterList;
    end
    return objList;
  end
  
  def topTenMostViewed()
    return LogConsult.top_consulted()
  end
  
  def getCollectionAuthenticationInfo(collection_id)
    result = Hash.new
    collection = Collection.find_by_id(collection_id)
    logger.info("[metaSearch][getCollectionAuthenticationInfo] HOST : #{collection.host}")
    result["post_data"] = collection.post_data
    result["action"] = collection.host
    return result
  end
  
  def getTheme(t)
    theme = SearchTabSubject.new();
    tabs  = self.GetTabs();
    i     = 0;
    
    while ((!tabs[i].name.nil?) && 
     (!t.nil?) &&
     (tabs[i].name!=t))
      i += 1
      logger.info("[metaSearch][getTheme] boucle : " + tabs[i].name)
    end
    if (!tabs[i].id.nil?) 
      t = tabs[i].id
    end
    logger.info("[metaSearch][getTheme] theme : '" + t.to_s + "'")
    return theme.CreateSubMenuTree(t);
  end
  
  def autoComplete(word, field)
    if (word.blank?)
      autocomplete_res  = []
    else
      autocomplete_res  = Array.new;
      texte             = word.downcase;
      texte             = UtilFormat.remove_accents(texte)
      address           = LIBRARYFIND_SOLR_HOST + "/autocomplete?terms.lower=#{texte}&terms.prefix=#{texte}&terms.lower.incl=false";
      if ((!field.blank?) && (field != 'keyword'))
        address         += "&terms.fl=autocomplete_" + field;
      end
      address           = URI.escape(address);
      _sRTime           = Time.now().to_f;
      response          = Net::HTTP.get_response(URI.parse(address));
      logger.info("#STAT# [AUTOCOMPLETE] requete: " + sprintf( "%.2f",(Time.now().to_f - _sRTime)).to_s) if LOG_STATS;
      
      case (response)
        when Net::HTTPSuccess
        response.body;
        _xpath = Xpath.new();
        parser = ::PARSER_TYPE;
        case (parser)
          when 'libxml'
          _parser         = LibXML::XML::Parser.new();
          _parser.string  = response.body;
          _xml            = LibXML::XML::Document.new();
          _xml            = _parser.parse;
          when 'nokogiri'
          _xml            = Nokogiri::XML.parse(response.body)
          when 'rexml'
          _xml            = REXML::Document.new(response.body);
        end
        nodes = _xpath.xpath_all(_xml, "//int");
        @ree  = nodes.length
        nodes.each do |node|
          autocomplete_res << node["name"];
        end
      else
        logger.info("ERROR Autocompleter Server not reachable");
      end
    end
    logger.info("#STAT# [AUTOCOMPLETE] fin: " + sprintf( "%.2f",(Time.now().to_f - _sRTime)).to_s) if LOG_STATS;
    return (autocomplete_res);
  end
  
  def SeeAlso(query)
    begin
      if SEE_ALSO_ACTIVATE == '1'
        _a = SeeAlsoSearch.new()
        return _a.search_relations(query)
      else
        return []
      end
    rescue => e
      logger.error("[MetaSearch] SeeAlso: #{e.message}")
      return []
    end
  end
  
  # synopsis spellcheck (string query, hash hSetting)
  
  def spellCheck(query)
    if (SPELL_ACTIVATE != '1')
      return ([]);
    end
    arguments		= Hash.new();
    
    if (query.blank?)
      logger.info("query is empty or nil");
      return ;
    end
    arguments["q"]                          = "aaaaaaaaaaaa";
    arguments["spellcheck.q"]               = query;
    arguments["spellcheck"]                 = true;
    arguments["spellcheck.extendedResults"] = true;
    arguments["spellcheck.count"]           = SPELL_COUNT;
    arguments["spellcheck.onlyMorePopular"] = true;
    arguments["spellcheck.collate"]         = true;
    conn                                    = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
    
    begin
      request   = Solr::Request::SpellcheckCompRH.new(arguments);
      logger.info("info request : " + request.handler);
      logger.info("body request : " + request.to_s);
      logger.info("request : " + request.inspect);
      response	= conn.send(request);
    rescue => e
      logger.info("exception " + e.message);
    end
    if (response.nil?)
      return (nil);
    end
    return (response.get_response());
  end
  
  def GetMoreInfoForISBN(isbn, with_image = true)
    if ((isbn.nil?) || (isbn.blank?))
      return (nil);
    end 
    hResponse = Hash.new();
    _w  = ElectreWebservice.new(logger)
    logger.info("[MetaSearch] : Electre connection")
    hResponse["back_cover"]        = _w.back_cover(isbn)
    hResponse["toc"] = _w.table_of_contents(isbn)
    if with_image
      hResponse["image"]            = _w.image(isbn);
    end
    logger.info("[MetaSearch] [GetMoreInfoForISBN] : #{hResponse.inspect}")
    return (hResponse)
  end
  
  def GetEditorials(id)
    return Editorial.getEditorialsByGroupsId(id)
  end
  
  def GetPrimaryDocumentTypes
    return PrimaryDocumentType.find(:all)
  end
  
  def setInfosUser(infoUser)
    @infos_user = infoUser
    logger.info("[MetaSearch][setInfosUser] Setting infos user : #{infoUser.inspect}")
    @log_management = LogManagement.new
    @log_management.setInfosUser(@infos_user)
  end
  
end 
