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
#
# = Webservice for search in Libraryfind
# 
# * <tt>Search</tt> is the first method to call with parameters for search. This method return a array of jobs.
# * <tt>check_job_status</tt> returns the states of jobs.
# * <tt>GetJobRecord</tt> must be called when all jobs are finished for retrieved all results.
# 
# This methods are accessible by this url: <tt>http ://<SERVEUR>/json/<METHOD></tt>
#
# == Variables in HTTP Header
# See JsonApplicationController and method analyse_request
#
# Parameters in <b>bold</b> are required, the <em>others</em> are optionals
#
#

class JsonController < JsonApplicationController
  include SearchHelper
  
  def initialize #:nodoc:
    super
  end
  
  # == Create a search and save history_search
  # <em>ex:  search?query[string]='word'&sets=g42</em>
  #
  # Parameters:
  # * <b>query[string1]</b> : keyword for search. String.  
  # * <b>sets</b> : id group collection with prefix 'g'. String (ex: g1)
  # * <tt>query[max]</tt> : results max by collection. Integer
  # * <tt>query[string2]</tt> : keyword 2 for search. String
  # * <tt>query[string3]</tt> : keyword 3 for search. String
  # * <b>query[field_filter1]</b> : filter type. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>query[field_filter2]</tt> : filter type 2. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>query[field_filter3]</tt> : filter type 3. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>query[operator1]</tt> : operateur 1. String. ex: AND, OR, NOT
  # * <tt>query[operator2]</tt> : operateur 2. String. ex: AND, OR, NOT
  # * <tt>tab_template</tt> : tab template. String. ex: ALL, BOOK, etc..
  # * <tt>theme_id</tt> : id #search_tab_subject. Integer
  # * <tt>log_ctx</tt> : from research for statistics. String. ex: search, see_also
  # @return {results => {jobs_id => array of jobs, history_id => integer}, error => error if error != 0, message => "error message"}
  def Search 
    error     = 0;
    _sTime    = Time.now().to_f
    id_search = -1
    begin
      init_search
      
      logger.debug("params : #{@sets}, #{@type}, #{@query}, #{@start}, #{@max}, #{@operator}")
      ids = $objDispatch.search_async(@sets, @type, @query, @start, @max, @operator)
      logger.debug("#STAT# [JSON] search 1 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      if (!ids.nil?)
        search_input = ""
        search_group = ""
        search_type = ""
        tab_template = ""
        search_operator1 = ""
        search_type2 = ""
        search_input2 = ""       
        search_operator2 = ""
        search_type3 = ""
        search_input3 = ""
        
        cpt = 0
        @query.each do |v|
          if (cpt == 0)
            search_input = v
          elsif (cpt == 1)
            search_input2 = v
          elsif (cpt == 2)
            search_input3 = v
          end
          cpt += 1
        end
        
        cpt = 0
        @operator.each do |v|
          if (cpt == 0)
            search_operator1 = v
          elsif (cpt == 1)
            search_operator2 = v
          end
          cpt += 1
        end
        
        cpt = 0
        @type.each do |v|
          if (cpt == 0)
            search_type = v
          elsif (cpt == 1)
            search_type2 = v
          elsif (cpt == 2)
            search_type3 = v
          end
          cpt += 1
        end
        
        if (!params["tab_template"].blank?)
          tab_template = params["tab_template"]
        end
        
        theme_id = extract_param("theme_id",Integer, -1);
        log_cxt = extract_param("log_cxt",String, nil);
        search_group = @sets
        
        id_search = $objAccountDispatch.saveHistorySearch(tab_template, search_input, search_group, search_type, search_operator1,
                                                          search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id, log_cxt)
        
        logger.debug("#STAT# [JSON] search 2 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      end
    rescue => e
      error = -1;
      logger.error("[Json Controller][search] Error : " + e.message);
      logger.debug("[Json Controller][search] Error : " + e.backtrace);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results => {"jobs_id" => ids, "history_id" => id_search },
      :error   => error
    }) 
    logger.debug("#STAT# [JSON] search " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end 
  
  # == Checks the status of research from jobs 
  # <em>ex:  check_job_status?id[]=123&id[]=124</em>
  #
  # Parameters:
  # * <b>id[]</b> : array of jobs. [Integer].  
  # @return {results => array of #JobItem, error => error if error != 0, message => "error message"}
  def check_job_status
    error = 0;
    results = nil;
    begin
      if params[:id] != nil 
        results = $objDispatch.check_job_status(params[:id])
      end
    rescue => e
      error = -1;
      logger.error("[Json Controller][checkJobStatus] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results => results,
      :error   => error
    })
  end
  
  # == Get records by jobs id with pagination
  # <em>ex: GetJobRecord?id[]=12&id[]=122&page_size=10&page=1</em>
  #
  # Parameters:
  # * <b>id[]</b> : array of jobs. [Integer].  
  # * <b>page</b> : page number to return. Integer
  # * <tt>page_size</tt> : number of records to return. Integer (default (NB_RESULT_MAX))
  # * <b>notice_display</b> : get only one details record and some information for pagination. Integer (O or 1)
  # * <b>group</b> : id group collection with prefix 'g'. String (ex: g1)
  # * <b>sort_value</b> : sorting criteria.[relevance, dateup, datedown, authorup, authordown, titleup, titlefdown, harvesting_date]. String ex: 'relevance'
  # * <tt>filter</tt> : filters. name of facette and value. String. ex: "author#Name/material_type#Base"
  # * <tt>log_ctx</tt> : context of this call for statistics. String. ex: search, notice, account, basket
  # * <tt>log_action</tt> : cause of this call for statistics. String (ex: consult, rebonce, pdf, email, print )
  # * <tt>filter</tt> : filters. name of facette and value. String. ex: "author#Name/material_type#Base"
  # * <tt>with_facette</tt> : get facets. Integer (0 or 1) 
  # * <tt>stop_search</tt> : kill all jobs not finished. Integer (0 or 1) 
  # * <tt>temps</tt> : get records before this time. String. timestamp
  # * <tt>with_total_hits</tt> : return last result of #check_job_status method. Integer (0 or 1)
  #
  # === If notice_display == 0
  # @return {:results => {:results => #Record array, :facette => array facetes, :page => page list, total_hits => Array of #JobItem, hits => Integer}, error => error if error != 0, message => "error message"}
  # 
  # === If notice_display == 1
  # @return {:results => {:current => #Record,:next => has a next record Integer (0 or 1), :previous => has a previous record Integer (0 or 1), :facette => array facetes, :total_hits => Array of JobItem, hits => Integer}, error => error if error != 0, message => "error message"}
  def GetJobRecord
    error   = 0;
    message = ""
    _sTime = Time.now().to_f
    headers["Content-Type"] = "text/plain; charset=utf-8"
    begin
      
      log_action = extract_param("log_action",String,"");
      log_cxt = extract_param("log_cxt",String,"");
      
      t = RecordController.new();
      
      # get jobs id
      id = params[:id].blank? ? raise("id is null please fill it") : params[:id];
      
      # get max records by database
      max = params[:max].blank? ? max_search_results() : params[:max];
      
      # get booleans value
      with_total_hits = (params[:with_total_hits].blank? or (!params[:with_total_hits].blank? and params[:with_total_hits] == '1'))
      with_facette = true
      if (!params[:with_facette].blank? and params[:with_facette] == '0')
        with_facette = false
      end
      
      # get results by pages
      @page_size  = NB_RESULTAT_MAX
      if (!params[:page_size].blank?) 
        begin
          @page_size = Integer(params[:page_size]);
          if @page_size <= 0
            @page_size  = NB_RESULTAT_MAX
          end
        rescue => e
          logger.warn("[JsonController][GetJobRecord] for page_size => #{e.message} #{e.backtrace.join('\n')}")
        end
      end
      
      # get id collection_group
      group  = -1
      if (!params[:group].blank?) 
        begin
          group = params[:group].slice(1,params[:group].length-1)
          group = Integer(group)
        rescue => e
          group = -1
          message = e.message
          logger.warn("[JsonController][GetJobRecord] for group => #{e.message}")
        end
      end
      
      # get sort value
      @sort_value = params[:sort].blank? ? 'relevance': params[:sort]
      
      # get filter values
      @filter     = params[:filter].blank? ? nil : params[:filter].collect! {|items| items.split('#')}
      logger.debug("[JsonController][GetJobRecord] params: #{id.inspect} max: #{max} group: #{group} sort:#{@sort_value} filter:#{@filter.inspect} page_size:#{@page_size}") 
      logger.debug("[JsonController][GetJobRecord] options: with_total_hits: #{with_total_hits} with_facette:#{with_facette}")
      logger.debug("#STAT# [JSON] GetJobRecord 1 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      
      if (log_action == "facette")
        begin
          $objAccountDispatch.addLogFacette(@filter);
        rescue => e
          logger.error("[JsonController][GetJobRecord] addLogFacette error : #{e.message}")
        end
      end
      # stop search
      stop_search = extract_param("stop_search",Integer,0);
      if (stop_search == 1) 
        for job in id
          item=$objDispatch.check_job_status(job)
          if item.status==JOB_WAITING
            if item.thread_id.to_i>0
              begin
                logger.debug("[JsonController][GetJobRecord] KillThread for job: #{job}")
                $objDispatch.KillThread(job, item.thread_id)
              rescue Exception => e
                logger.error("[JsonController][GetJobRecord] error : #{e.message}")
              end
            end
          end
        end
      end
      
      temps = extract_param("temps",String,nil);
      
      # get results
      logger.debug("[JsonController][GetJobRecord] search results for jobs: #{id} and max:#{max}")
      @results    = $objDispatch.GetJobsRecords(id, max, temps);
      logger.debug("[JsonController][GetJobRecord] after getJobsRecords size of Result : " + @results.length.to_s);
      logger.debug("#STAT# [JSON] GetJobRecord 2 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      
      logger.debug("[JsonController][GetJobRecord] filter : #{@filter.inspect}") 
      
      # set params to recordController
      t.build_results(@results, @sort_value, @filter);
      # call filter results      
      t.filter_results;
      # get results to sort
      @results = t.sort_results;
      # set hits after filter
      hits = 0
      if !@results.nil?
        hits = @results.size
      end
      logger.debug("[JsonController][GetJobRecord] after sort size of Result : " + @results.length.to_s);
      logger.debug("#STAT# [JSON] GetJobRecord 3 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      
      # get total_hits
      @total_hits = nil
      if with_total_hits
        @totalhits = $objDispatch.GetTotalHitsByJobs(id);
      end
      logger.debug("#STAT# [JSON] GetJobRecord 4 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      # generate page_list
      lf_paginate;
      
      # construct facette
      facette = nil
      if with_facette
        facette = t.build_databases_subjects_authors();
      end
      logger.debug("#STAT# [JSON] GetJobRecord 5 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
      
      notice_display = params[:notice_display].blank? ? "0": params[:notice_display];
      
      if (notice_display == "1")
        if @results_page.nil? or @results_page.empty?
          raise "error"
        end
        
        log_action = "consult";
        log_cxt = "notice"
        current,error = GetIdGeneric(@results_page[0].id, log_action, log_cxt);
        
        render :text => Yajl::Encoder.encode({:results  => {
            :current  => current,
            :next     => @show_next,
            :previous => @show_previous,
            :facette  => facette,
            :page     => nil,
            :totalhits  => @totalhits,
            :hits => hits
          },
          :error    => error, 
          :message => message
        })
        logger.debug("#STAT# [JSON] GetJobRecord by notice " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
        return ;
      else
        # tab id
        # merge record with notice
        logger.debug("[JsonController][GetJobRecord] @results_page : #{@results}") 
        @results_page = $objCommunityDispatch.mergeRecordWithNotices(@results_page)
        logger.debug("[JsonController][GetJobRecord] @results_page after : #{@results_page}") 
      end
    rescue => e
      error = -1;
      message = e.message
      logger.error("[Json Controller][GetJobRecord] Error : " + e.message);
      logger.error("[Json Controller][GetJobRecord] " + e.backtrace.join("\n"))
    end 
    logger.debug("#STAT# [JSON] GetJobRecord 6 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
    render  :text => Yajl::Encoder.encode({ :results    => { :results => @results_page,
        :facette    => facette,
        :page       => @page_list,
        :totalhits => @totalhits,
        :hits => hits
      },
      :error      => error,
      :message      => message
    })
    logger.debug("#STAT# [JSON] GetJobRecord " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    return ;
  end	
  
  # == List all collections
  #
  # @return {results => Array of #Collection, :error => code error}
  def ListCollections
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.ListCollections
    rescue => e
      error = -1;
      logger.error("[Json Controller][ListCollection] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  
  # == List group of collection
  #
  # Parameter
  # * <tt>advanced</tt> : only group for advanced search. Integer (O or 1)   
  # @return {results => Array of #Collection, error => code error }
  def ListGroups
    error   = 0;
    results = nil;
    begin
      bool_advanced = !params[:advanced].blank? && params[:advanced] == "1" 
      results = $objDispatch.ListGroups(bool_advanced)
    rescue => e
      error = -1;
      logger.error("[Json Controller][ListGroups] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get collections in a group of collection
  #
  # Parameter
  # * <b>name</b> : name of group collection. String   
  # @return {results => Array of #Collection, error => code error }
  def GetGroupMembers
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.GetGroupMembers(params[:name])
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetGroupMembers] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get tabs
  #
  # @return {results => Array of #SearchTab, error => code error }
  def GetTabs
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.GetTabs;
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetTabs] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get filters for all tabs
  #
  # @return {results => Array of #SearchTabFilter, error => code error }
  def GetFilter
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.GetFilter;
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetFilter] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Kill a job
  # 
  # This method can be called in order to stop one job in a research.
  # The parameter "threadid" is returned in a JobItem
  # Parameters
  # * <b>jobid</b> : job id. Integer 
  # * <b>threadid</b> : process id. Integer 
  #
  # @return {error => code error }
  def KillThread
    error = 0;
    begin
      jobid = params[:jobid]
      threadid = params[:threadid]
      result = $objDispatch.KillThread(jobid, threadid)
    rescue => e
      error = -1;
      logger.error("[Json Controller][KillThread] Error : " + e.message);
    end
    
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :text => Yajl::Encoder.encode({:result  => result, :error => error})
  end
  
  # == Get Top ten of records viewed
  # 
  # This method is based on the statistics
  #
  # @return {results => Array of #Record, error => code error }
  def TopTenMostViewed()
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.topTenMostViewed();
    rescue => e
      error = -1;
      logger.error("[Json Controller][TopTenMostViewed] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get all themes for tabs
  # 
  # You can specify a tab name. #SearchTab
  #
  # Parameter
  # * <tt>theme</theme> : id of #SearchTab
  # @return {results => Array of #SearchTabSubjects, error => code error }
  def GetTheme()
    error   = 0;
    results = nil;
    begin
      theme = params[:theme].blank? ? nil : params[:theme];
      results = $objDispatch.getTheme(theme);
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetTheme] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Obtain a detailed record with its id
  # 
  # The parameter idSearch is only required for a record retourned by a synchronous connector (ex: Z39.50, SRU etc..)
  #
  # Parameter
  # * <b>idDoc</b> : id of record. String
  # * <b>idCollection</b> : id of #Collection. Integer
  # * <em>idSearch</em> : id of #CachedSearch. Integer.
  # * <tt>log_ctx</tt> : context of this call for statistics. String. ex: search, notice, account, basket
  # * <tt>log_action</tt> : cause of this call for statistics. String (ex: consult, rebonce, pdf, email, print )
  # @return {results => #Record, error => code error, message => error message}
  def GetId()
    _sTime = Time.now().to_f
    error   = 0;
    results = nil;
    message = ""
    begin
      log_action = extract_param("log_action",String,"");
      log_cxt = extract_param("log_cxt",String,"");
      
      if ((!params[:idDoc].blank?) && (!params[:idCollection].blank?))
        idDoc     = params[:idDoc];
        idCol     = params[:idCollection];
        idSearch  = params[:idSearch];
        
        if (idSearch.blank?)
          idSearch = 0;
        end
        results, error = GetIdGeneric("#{idDoc};#{idCol};#{idSearch}", log_action, log_cxt);
      else
        error = 102;
      end
    rescue => e
      error = -1;
      message = e.message
      logger.error("[Json Controller][GetId] Error : " + e.message);
      logger.error("[Json Controller][GetId] #{e.backtrace}")
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error,
      :message    => message
    })
    logger.debug("#STAT# [JSON] GetId " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Autocomplete 
  # 
  # This method return a list of words from characters
  #
  # Parameter
  # * <b>word</b> : id of record. String
  # * <em>field</em> : name of index (#SearchTabFilter.field_filter). String. ex: keyword
  #
  # @return {results => array of words, error => code error, message => error message}
  def AutoComplete
    error   = 0;
    results = nil;
    begin
      word = nil;
      field = nil;
      
      if (!params[:word].blank?)
        word  = params[:word];
      end
      if (!params[:field].blank?)
        field  = params[:field];
      end
      results = $objDispatch.autoComplete(word, field);
    rescue => e
      error = -1;
      logger.error("[Json Controller][AutoComplete] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == SpellCheck 
  # 
  # This method is as a spell checker and returns a list of words from a word
  #
  # Parameters
  # * <b>word</b> : word. String
  # * <em>field</em> : name of index (#SearchTabFilter.field_filter). String. ex: keyword
  #
  # @return {results => array of words, error => code error, message => error message}
  def SpellCheck
    error   = 0;
    results = nil;
    begin
      query = String.new();
      if (!params[:query].blank?)
        query   = params[:query];
      end
      results   = $objDispatch.spellCheck(query);
    rescue => e
      error = -1;
      logger.error("[Json Controller][SpellCheck] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == SeeAlso 
  # 
  # This method returns a list of words from a word.
  # It's a list of synonyms
  #
  # Parameter
  # * <b>query</b> : word. String
  # * <em>field</em> : name of index (#SearchTabFilter.field_filter). String. ex: keyword
  #
  # @return {results => array of words, error => code error, message => error message}
  def SeeAlso
    error   = 0;
    results = nil;
    begin
      logger.debug("[SeeAlso] params: #{params.inspect}")
      _q = params[:query]
      results = $objDispatch.SeeAlso(_q);
    rescue => e
      error = -1
      logger.error("[Json Controller][SeeAlso] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == GetMoreInfoForISBN 
  # 
  # This method use ElectreWebService for return an abstract and a table of content from a isbn number
  #
  # Parameter
  # * <b>id</b> : isbn. String
  #
  # @return {results => {:quatrieme => abstract String, tableDesMatiers => summary }, error => code error, message => error message}
  def GetMoreInfoForISBN()
    _sTime = Time.now().to_f
    error   = 0;
    results = nil;
    begin
      isbn = params[:id];
      logger.debug("[Json Controller][getMoreInfo] ISBN : " + isbn.to_s);
      results = $objDispatch.GetMoreInfoForISBN(isbn, false);
    rescue => e
      error = -1;
      logger.error("[Json Controller][getMoreInfo] Error : " + e.message);
      logger.error("[Json Controller][getMoreInfo] Error : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => { 
        :quatrieme => results["back_cover"] , 
        :tableDesMatieres => results["toc"] },
      :error    => error
    })
    logger.debug("#STAT# [JSON] GetMoreInfoForISBN " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == GetIds 
  # 
  # Return an array of records by an array of identifiers
  #
  # Parameters
  # * <b>ids</b> : array of Idenfifier. String. ex: [1212332;12;1212] idRecord;idCollection[;IdSearch]
  # * <tt>log_ctx</tt> : context of this call for statistics. String. ex: search, notice, account, basket
  # * <tt>log_action</tt> : cause of this call for statistics. String (ex: consult, rebonce, pdf, email, print )
  # @return {results => Array of #Record, error => code error}
  def GetIds
    error   = 0;
    results = Array.new();
    _sTime = Time.now().to_f
    begin
      
      log_action = extract_param("log_action",String,"");
      log_cxt = extract_param("log_cxt",String,"");
      
      if (!params[:ids].blank?)
        notices = params[:ids]
        
        notices.each do |notice|
          res, err = GetIdGeneric(notice, log_action, log_cxt);
          if (!res.nil?)
            results.push({:results => res, :error => err});
          end
        end
      end
    rescue => e
      logger.error("[Json Controller][GetIds] Error : " + e.message + e.backtrace.join("\n"));
      error = -1;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({   
      :results  => results,
      :error    => error
    })
    logger.debug("#STAT# [JSON] GetIds " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
  end
  
    # == getCollectionAuthenticationInfo 
  # 
  # Return an array of records by an array of identifiers
  #
  # Parameters
  # 
  # @return {results => Array of #Record, error => code error}
  def getCollectionAuthenticationInfo
    error   = 0;
    collection_id = ""
    if (!params[:collection_id].blank?)
        collection_id = params[:collection_id]
    end
    results = nil;
    begin
      results = $objDispatch.getCollectionAuthenticationInfo(collection_id);
    rescue => e
      error = -1;
      logger.error("[Json Controller][getCollectionAuthenticationInfo] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
    
  end
  
  # == GetPrimaryDocumentTypes 
  # 
  # Return an array of #PrimaryDocumentType 
  # PrimaryDocumentType are used in the material_type property of records
  #
  # @return {results => Array of #PrimaryDocumentType, error => code error}
  def GetPrimaryDocumentTypes
    error   = 0
    results = nil
    _sTime = Time.now().to_f
    begin
      results = $objDispatch.GetPrimaryDocumentTypes
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetPrimaryDocumentTypes] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
    logger.debug("#STAT# [JSON] GetPrimaryDocumentTypes " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  private
  
  def GetIdGeneric(id, log_action, log_cxt) #:nodoc:
    _sTime = Time.now().to_f
    results = nil
    error   = 0
    results = $objDispatch.GetId(id, {:log_action => log_action, :log_cxt => log_cxt});
    logger.debug("#STAT# [JSON] GetIdGeneric (1)" + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    if (results.nil?)
      error = 103;
      r = Record.new();
      r.id = id;
      tab = $objCommunityDispatch.mergeRecordWithNotices([r])
    else
      tab = $objCommunityDispatch.mergeRecordWithNotices([results])
    end
    logger.debug("#STAT# [JSON] GetIdGeneric (2)" + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    if (tab.empty?)
      return ([nil, 104])
    end
    results = tab[0];
    return ([results, error]);
  end
end
