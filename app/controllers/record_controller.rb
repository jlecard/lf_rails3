# $Id: record_controller.rb 1294 2009-03-23 08:07:19Z reeset $

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
class RecordController < ApplicationController
  require_dependency 'user' 
  include ApplicationHelper
  include SearchHelper
  include CartHelper 
  include ERB::Util
  layout "libraryfind", :except => [:spell_check,:advanced_search, :cart, :build_results, :see_also]
  
  def build_results(_results, _sort_value, _filter)
    @results    = _results
    @sort_value = _sort_value
    @filter     = _filter
  end
  
  def index
    begin
      consult = LogConsult.new
      @mostViewed = consult.top_consulted
    rescue
      @mostViewed = nil
    end
    init_defaults
    render(:action => 'accueil_all')
  end
  
  def search
    @client_ip = request.env["HTTP_CLIENT_IP"]
    @client_host = request.env["HOST"]
    @client_url = request.url
    @IsMobile = false
    if params[:mobile] and params[:mobile] == "true"
      @IsMobile = true
    end
    init_defaults
    render(:action=>'accueil_all')
  end
  
  def set_query_and_operator
    
   @tab_query_string = []
   if params[:string1]
     @tab_query_string << params[:string1] if !params[:string1].blank? 
     @tab_query_string << params[:string2] if !params[:string2].blank?
     @tab_query_string << params[:string3] if !params[:string3].blank?
   end
   @sets ||= params[:query_sets]
    @field_filter = []   
    @field_filter[0] = params[:field_filter1] if !params[:field_filter1].blank? 
    @field_filter[1] = params[:field_filter2] if !params[:field_filter2].blank? 
    @field_filter[2] = params[:field_filter3] if !params[:field_filter3].blank?
    
    
   @operator = []
   @operator[0] =  params[:operator1].blank? ? "AND" : params[:operator1] 
   @operator[1] =  params[:operator2].blank? ? "AND" : params[:operator2]
    
  end
  
  def advanced_search
    init_defaults
    render(:action=>'advanced_search')
  end
  
  def retrieve
    session_pagination
    session_max_search_results
    default_tab
 
    logger.debug("[RecordController][retrieve]")
    if (params[:start_search] != "false")
      if (params[:query] != nil)
        if (params[:rebonce] != nil)
          items = {:query => "#{html_escape(params[:query][:string1])}", :filter =>"#{html_escape(params[:query][:field_filter1])}", :host => "#{request.remote_addr}"};
          LogGeneric.addToFile("LogRebonceUsage", items)
        end
        logger.debug("[retrieve] idTab:#{@idTab}")
        
        init_defaults
        init_query_and_type(params)
        if !@query[0].blank? and !@query[0].to_s.strip.blank?
          init_search  
          if @sets and !@sets.empty?
            logger.debug("[retrieve] searching for query: " + @query.to_s + " and type: " + @type.to_s)
            if @IsMobile and !request.user_agent.downcase.index('opera mini').nil?
              dep_find_search_results
              render(:action => @tab_template)
            else
              @jobs = $objDispatch.search_async(@sets, @type, @query, @start, @max, @operator)
              render(:action => 'intermediate')
            end
          else
            flash.now[:notice]="No collection group selected"
            render(:action=>"accueil_all")
          end
        else
          flash.now[:notice] = "No query or empty query"
          render(:action=>"accueil_all")
        end
      else
        flash.now[:notice] = "No query"
        render(:action=>"accueil_all")
      end 
    else
      init_defaults
      if !params[:query].blank?
        init_query_and_type(params)
      else
        @query=['']
      end
      if params[:sets].blank?
        @sets=params[:sets]
      else
        @sets=selected_sets
        if !@sets or @sets.empty?
          init_sets
        end
      end
      if @sets.rindex(',') == @sets.length - 1
        @sets=@sets.chop
      end
      render(:action=>"accueil_all")
    end
  end 
  
  #this method is used during pagination/filtering/sorting to keep user with the same results.  For example,
  #if a user is paging through results that have been sorted, this method will forward to those
  #sorted results.
  def retrieve_page
    init_defaults
    set_query_values
    init_search
    find_search_results
    render(:action => @tab_template)
  end
  alias :show :retrieve_page
  
  
  # When clicking on exploration by theme
  # link made like : /record/retrieve_theme?sets=g4
  #
  def retrieve_theme
    @idTab	= params[:idTab]
    items		= {:types => params[:sets]}
    
    if params[:filter].blank?
      subValue	= params[:filter].split(/\//);
      if (subValue.length > 0)
        items		= {:types => "#{subValue[subValue.length - 1].split(/:/)[0]}", :host => "#{request.remote_addr}"}
      else
        items		= {:types => "#{subValue[0].split(/#{FILTER_SEPARATOR}/)[0]}", :host => "#{request.remote_addr}"}
      end
    end
    LogGeneric.addToFile("LogFacetteUsage", items)
    if params[:sets].nil? and !params[:sets].to_s.strip.blank?
      init_defaults
      @query		= []
      @type			= []
      @operator	= []
      
      init_search
      logger.debug("searching for query: " + @query.to_s + " and type: " + @type.to_s)
      if @IsMobile and !request.user_agent.downcase.index('opera mini').nil?
        dep_find_search_results
        render(:action => @tab_template)
      else
        @jobs	= $objDispatch.search_async(@sets, @type, @query, @start, @max, @operator)
        render(:action => 'intermediate')
      end
    else
      init_defaults
      redirect_to(:action=>"accueil_all")
    end 
  end 
  
  def dep_find_search_results(_type=@type, _query=@query, _sets=@sets, _start=@start, _max=@max)  
    logger.debug("searching for type="+_type.to_s+" query="+_query.to_s+" sets="+_sets.to_s+" start="+_start.to_s+" max="+_max.to_s)
    @results = dep_ping_for_results(_sets, _type, _query, _start, _max) 
    logger.debug("Results Found: " + @results.length.to_s)
    if @results.nil? or @results.empty?
      flash.now[:notice]	= translate('NO_RESULTS')
    else
      collect_database_errors
      build_all_databases
      filter_results
      sort_results
      filter_images
    end
  rescue Exception => e
    logger.error("RecordController caught ERROR: " + e.to_s)
    logger.error(e.backtrace.to_s)
    flash.now[:error]	= translate('ERROR_OCCURED',[e.to_s])
  end
  
  def dep_ping_for_results(_sets=@sets, _type=@type, _query=@query, _start=@start, _max=@max, _operator=@operator)  
    ids 				= $objDispatch.search_async(_sets, _type, _query, _start, _max, _operator) 
    completed		= []
    errors			= []
    start_time	= Time.now
    while (((completed.length.to_i+errors.length.to_i) < ids.length.to_i) && ((Time.now-start_time) < 30))
      sleep(0.5)
      count			= 0
      for id in ids
        if (!completed.include?(id))
          #clear the record cache
          ActiveRecord::Base.clear_active_connections!() 
          item		= $objDispatch.check_job_status(id)
          count		= count + 1
          if (item.status == -1)
            if (!errors.include?(id))
              errors << id
            end
          elsif (item.status == 0)
            logger.debug("completed: " + id.to_s)
            completed << id
          end
        end
      end
    end
    return ($objDispatch.get_jobs_records(completed, _max, 4))
  end
  
  def collect_database_errors
    errors	= ""
    vendors	= Array.new
    for record in @results
      # if record.error!=nil and record.error!=""
      #   if !vendors.include?(record.vendor_name)
      #     vendors<<record.vendor_name
      #     errors=record.vendor_name+": "+record.error+"<br>"
      #   end
      # end
    end
    if (errors != "")
      flash.now[:notice]=translate('DB_ERRORS',[errors])
    end
  end
  
  def find_search_results
    @results	= $objDispatch.get_jobs_records(@completed, max_search_results)
    if @results.nil? or @results.empty?
      flash.now[:notice]=translate('NO_RESULTS')
    else
      process_results
    end
  rescue Exception => e
    logger.error("RecordController caught ERROR: " + e.to_s)
    logger.error(e.backtrace.to_s)
    flash.now[:error]=translate('ERROR_OCCURED',[e.to_s])
  end
  
  def process_results
    build_all_databases
    #
    # Process here the document type
    #   ---
    #
    filter_results
    if (@IsMobile != true)
      build_databases_subjects_authors
    end
    sort_results
    filter_images
  end
  
  def init_pinging_params
    @jobs = params[:jobs].nil? ? [] : params[:jobs].split(',') 
    @jobs 
  end
  
  def check_job_status
    @completed=[]
    @jobs_remaining=0
    @completed_targets=""
    @remaining_targets=""
    completed_items=[]
    init_pinging_params
    for id in @jobs
      item=$objDispatch.check_job_status(id)
      if item.status==0 
        @completed<<id
        completed_items<<item
      elsif item.status==1
        @jobs_remaining=@jobs_remaining+1
        if !item.target_name.blank?
          @remaining_targets=@remaining_targets+item.target_name.to_s+"<br/>"
        end
      end
    end
    sorted_completed=completed_items.sort{|a,b|b.hits.to_i <=> a.hits.to_i}
    for target in sorted_completed
       if !target.target_name.blank?
        @completed_targets=@completed_targets+"<span id='completed_targets'>"+target.target_name.to_s+"</span>"+target.hits.to_s+" hits (total:#{target.total_hits})<br/>"
      end
    end
    if params[:mobile] != nil and params[:mobile] == true
      @IsMobile = true
    end
    render(:partial => 'pinging')
  end

  def finish_search
    logger.warn("----------------------------------------------------------------------------------") if LOG_STATS
    _sTime = Time.now().to_f
    @completed=[]
    @idTab = params[:idTab]
    @errors=Hash.new
    @private = Hash.new
    init_pinging_params
    for id in @jobs
      item=$objDispatch.check_job_status(id)
      if item.status==JOB_WAITING
        if item.thread_id.to_i>0
          begin
            if item.target_name!=nil
              flash.now[:notice]=translate('SEARCH_STOPPED') 
            end
            $objDispatch.KillThread(id, item.thread_id)
          rescue Exception => e
            logger.error("RecordController caught ERROR: " + e.to_s)
            logger.error(e.backtrace.to_s) 
          end
        end
      elsif item.status==JOB_FINISHED 
        @completed<<id
      elsif item.status==JOB_ERROR
        @errors[item.target_name]=item.error
      elsif item.status==JOB_PRIVATE
         objAuth = Authorize.new
         if objAuth.IsPrivateVisible(request.env['REMOTE_ADDR'], request.env['HTTP_REFERER']) == false
           @private[item.target_name]=item.error
         else
  	  @completed<<id
         end
      end
    end 
    logger.debug("#STAT# [FINISH_SEARCH] get_jobs " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
   
    init_defaults
    @jobs=[]
    @results= $objDispatch.get_jobs_records(@completed, @max, nil)
    logger.debug("#STAT# [FINISH_SEARCH] get_records " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    set_query_values
    init_search
    spell_check
    see_also
  #   @editorials = Editorial.getEditorialsByGroupsId(params[:query_sets].slice(1,params[:query_sets].length-1))
     @editorials = $objDispatch.GetEditorials(params[:query_sets].slice(1,params[:query_sets].length-1));
    if params[:mobile] != nil and params[:mobile] == 'true'
      @IsMobile = true
    end 
    if @results==nil or @results.empty?
      flash.now[:notice]=flash.now[:notice].to_s+'<br/>'+translate('NO_RESULTS')
    else
     process_results
   end
    render(:action => @tab_template,:layout=>true)
    logger.debug("#STAT# [FINISH_SEARCH] render " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    logger.debug("#STAT# [FINISH_SEARCH] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    logger.warn("----------------------------------------------------------------------------------") if LOG_STATS
  end
  
  def default_tab
    @idTab ||= params[:idTab] || 1
  end
  
  def init_defaults
    logger.debug("[RecordController][init_defaults]")
    #default_tab
    defaults
    @jobs=nil
    
    @filter_tab = SearchTabFilter.load_filter(default_tab)
    @linkMenu = SearchTab.load_menu
    @groups_tab = SearchTab.load_groups(default_tab)
    @theme = SearchTabSubject.new
    @TreeObject = @theme.CreateSubMenuTree
    @editorials = nil
    #Most viewed documents
    begin
      consult = LogConsult.new
      @mostViewed = consult.top_consulted
    rescue
      @mostViewed = nil
    end
    
    begin
      paginate_cart(2)
    rescue
      logger.debug("no cookie found !")
    end
    
    @page_size = NB_RESULTAT_MAX
    
    @seeAlso = []
    set_query_and_operator
  end
  
  def build_all_databases
    @all_databases = $objDispatch.GetTotalHitsByJobs(@completed)
  end
     
  #this method uses one loop to build 3 arrays to diplay to the user: databases, 
  #@databases is a list of all searched databases sorted on the number of hits
  #@subjects is a list of all subjects in search results sorted on the number of records with that subject
  #@authors is a list of all authors in search results sorted on the number of records with that author
  def build_databases_subjects_authors
    _database_hash = Hash.new  
    _material_type_hash = Hash.new  
    _subject_hash= Hash.new
    _author_hash=Hash.new
    _date_hash=Hash.new
    _lang_hash=Hash.new
    _theme_hash=Hash.new
    _availability_hash=Hash.new
    for _record in @results    
      
      if _record.hits==nil or _record.hits==''
        _record.hits="0"
      end
     	
      if _database_hash[_record.vendor_name]==nil 
  	     _database_hash[_record.vendor_name]=1
      else  
        _database_hash[_record.vendor_name]= _database_hash[_record.vendor_name]+1
      end   

      #if _record.availability == "online" and _record.direct_url == ""
      #  _record.availability = ""
      #end

      if _record.availability == "online" and _record.direct_url == ""
        flag_link = 0
	if _record.examplaires.size > 0
	  for _exemp in _record.examplaires
	    if _exemp["link"] != ""
	      flag_link = 1
	      break
	    end
	  end
	end
	if (flag_link == 0)
	  _record.availability = ""
      	end
      end

      if _availability_hash[_record.availability]==nil 
        _availability_hash[_record.availability]=1
      else  
        _availability_hash[_record.availability]=_availability_hash[_record.availability]+1
      end  
  	
      if _material_type_hash[_record.material_type]==nil 
        _material_type_hash[_record.material_type]=1
      else  
        _material_type_hash[_record.material_type]=_material_type_hash[_record.material_type]+1
      end  
      
      _subjects=_record.subject
      if _subjects!=nil and _subjects!=''
        _subject_array=_subjects.split(";")
        _subject_array.delete_if {|a| a.strip==""}
        for _subject in _subject_array
          _subject=_subject.strip
          if _subject_hash[_subject]==nil 
  #          if _subject_hash.length >= 15
  #             logger.fatal("condiotion bizare:" + _subject_hash.sort.inspect)
  #             
  #            _subject_hash = _subject_hash.sort.inject({}) {|h, elem| h[elem[0]]=elem[1]; h}
  #            _subject_hash.shift
  #          end
            _subject_hash[_subject]=1
          else  
            _subject_hash[_subject]=_subject_hash[_subject]+1
          end
        end
      end
      
      _authors=_record.author
      if _authors!=nil and _authors!=''
        _author_array=_authors.split(";")
        _author_array.delete_if {|a| a.strip==""}
        for _author in _author_array
          _author=_author.strip
          if _author_hash[_author]==nil 
  #          if _author_hash.length >= 15
  #            _author_hash = _author_hash.sort.inject({}) {|h, elem| h[elem[0]]=elem[1]; h}
  #            _author_hash.shift
  #          end
            _author_hash[_author]=1
          else  
            _author_hash[_author]=_author_hash[_author]+1
          end
        end
      end
     
     if !_record.date.nil?
       date = _record.date[0,4]
       if !date.nil? and !date.starts_with?("0")
         if _date_hash[date]==nil
            _date_hash[date]=1
         else  
           _date_hash[date] += 1
         end
       end
     end
   
     if (!_record.lang.blank?)
        if _lang_hash[_record.lang]==nil 
          _lang_hash[_record.lang]=1
        else  
  					_lang_hash[_record.lang]=_lang_hash[_record.lang]+1
        end  
     end
     
     if THEME_ACTIVATE and !_record.theme.blank?
       _record.theme.split(";").each do |t|
          _tTab = t.split(THEME_SEPARATOR)
    		  if !_tTab[0].nil?
    			 _h = help_theme(_theme_hash, _tTab[0].strip)
    			 if !_tTab[1].nil?
    				  _h = help_theme(_h, _tTab[1].strip)
    				  if !_tTab[2].nil?
    					 help_theme(_h, _tTab[2].strip)
    				  end
    			 end
    		  end
       end
     end
     
    end
    @dates=_date_hash.sort {|a,b| b[0].to_i<=>a[0].to_i}
    @langs=_lang_hash.sort {|a,b| b[1].to_i<=>a[1].to_i}
  	logger.debug("[recordControler] @langs : " + @langs.inspect);
    @authors=_author_hash.sort {|a,b| b[1].to_i<=>a[1].to_i}
    @subjects=_subject_hash.sort {|a,b| b[1].to_i<=>a[1].to_i}
    @databases=_database_hash.sort {|a,b| b[1].to_i <=> a[1].to_i} 
    @material_types=_material_type_hash.sort {|a,b| b[1].to_i<=>a[1].to_i}  
    @availabilities=_availability_hash.sort {|a,b| b[1].to_i <=> a[1].to_i}
    @themes=_theme_hash.sort {|a,b| b[1][0].to_i <=> a[1][0].to_i}
    @themes.each do |lab, val|
      val[1] = val[1].sort {|a,b| b[1][0].to_i <=> a[1][0].to_i}
      val[1].each do |lab2, val2|
        val2[1] = val2[1].sort {|a,b| b[1][0].to_i <=> a[1][0].to_i}
        val2[1].each do |lab3, val3|
        end
      end
    end
    
    if @authors.size > 20
      @authors = @authors[0..19]
    end
    
    if @subjects.size > 20
      @subjects = @subjects[0..19]
    end
    
    if @dates.size > 20
      @dates = @dates[0..19]
    end
     
    return {
            :date       => @dates, 
            :langs      => @langs, 
            :authors    => @authors, 
            :subjects   => @subjects, 
            :databases  => @databases, 
            :material   => @material_types, 
            :themes   => @themes,
            :availability  => @availabilities
            };
  end
  
  def help_theme(hash, indice)
    if hash[indice] == nil
        hash[indice] = Array.new()
        hash[indice][0] = 1
        hash[indice][1] = Hash.new()
    else
        hash[indice][0] += 1
    end
    return hash[indice][1]
  end
  
  def selected_sets
   checkboxes=params[:collection_group]
   if checkboxes!=nil
      for group in checkboxes 
        if group[1]=='1'
          @sets=@sets+group[0]+','
        end
      end
    end
    query_sets=params[:query_sets]
    if query_sets != nil
        @sets = query_sets+','
    end
    @sets
  end
  
  def init_sets
      begin
        @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
        @sets=""
        groups=@config["DEFAULT_GROUPS"].to_s.split(',')
        for group in groups
          _item = $objDispatch.GetGroupMembers(group)
          @sets = "#{@sets}#{_item.id},"
        end
      rescue Exception => e
        logger.error("RecordController caught ERROR: " + e.to_s)
        logger.error(e.backtrace.to_s)
        flash.now[:error]=translate('ERRORS_GETTING_GROUPS')
      end
  end    
  
  def filter_results
    if !@filter.blank? and !@results.blank? 
      for filter_pair in @filter
        if filter_pair!=nil and !filter_pair.empty?
          filter_type=filter_pair[0].to_s
          filter_value=filter_pair[1].to_s
          @results.delete_if {|_record| _record.send(filter_type)==nil or !_record.send(filter_type).downcase.include?(filter_value.downcase)}
        end
      end
#        if @results==nil or @results.empty?
#      flash.now[:notice]=translate('FILTER_DID_NOT_MATCH')
   # end
    end  
  end
  
    
  def filter_images
    if @results!=nil
      @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
      if @tab_template!=@config["IMAGES_TEMPLATE"]
        found_first=false
        filtered_results=Array.new
        for record in @results
          if record.material_type.downcase=="image"
            if !found_first
              found_first=true
              filtered_results<<record
            end
          else
            filtered_results<<record
          end 
        end
        @all_results=@results
        @results=filtered_results
      end
    end
  end
    
    
  def sort_results
    _nrec = Hash.new
    defaultNilValues
    for record in @results
      if defined? LIBRARYFIND_SPECIAL_WEIGHT
        if (defined?(record.oclc_num)==true and (record.oclc_num != nil or record.oclc_num != ''))
          if _nrec.has_key?(record.oclc_num) == true
            if _nrec[record.oclc_num].vendor_name.index(LIBRARYFIND_SPECIAL_WEIGHT) == nil
              if record.vendor_name.index(LIBRARYFIND_SPECIAL_WEIGHT) != nil
                _nrec[record.oclc_num] = record
              else
                if record.rank.to_i > _nrec[record.oclc_num].rank.to_i
                  _nrec[record.oclc_num] = record
                end
              end
            end
          else
            _nrec[record.oclc_num] = record
          end
        else
          _nrec[record.id] = record
        end
      end
      
      diff=8-record.date.length
      if diff > 0
        padding="0"*diff
        record.date=record.date+padding
      end
  		begin
        if ((!params.nil?) &&
         (!params[:query].nil?) &&
         (!params[:query][:string].nil?))
          underLine = params[:query][:string];
          underLine = underLine.gsub(/,,,/, '|') || underLine;
          underLine = Regexp.escape(html_escape(underLine));
          logger.debug("[Debug] : " + underLine);
          record.ptitle.gsub!(/(#{underLine})/i, '<span class="keyword">\1</span>')
          record.author.gsub!(/(#{underLine})/i, '<span class="keyword">\1</span>')
          record.subject.gsub!(/(#{underLine})/i, '<span class="keyword">\1</span>')
        end
  		rescue => e
  			logger.error("[Sort_results][UnderLine] : #{e.message}");
  		end
    end
  
    if defined? LIBRARYFIND_SPECIAL_WEIGHT
       @results = _nrec.values
    end
    
    if @sort_value=='relevance' or @sort_value==nil or @results==nil
      @results.sort!{|a,b| b.rank.to_f <=> a.rank.to_f} 
    else
      case @sort_value
        when "dateup"
          #Using 500000000-rank so that results are displayed with highest rank first
          @results=@results.sort_by{|a| [a.date,  500000000-a.rank.to_f]}  
        when "datedown"
          #using 100000000-date so that dates are displayed with highest first
          @results=@results.sort_by{|a| [100000000-a.date.to_i,  500000000-a.rank.to_f]}   
        when "authorup"
          @results=@results.sort_by{|a| [a.author,  500000000-a.rank.to_f]}  
        when "authordown"        
          @results=@results.sort_by{|a| [a.author,  a.rank.to_f]}  
          @results.reverse!
        when "titleup"
          @results=@results.sort_by{|a| [a.ptitle.mb_chars.normalize(:kd).gsub(/[^-x00-\x7F]/n, '').to_s.upcase,  500000000-a.rank.to_f]}
        when "titledown"
          @results=@results.sort_by{|a| [a.ptitle.mb_chars.normalize(:kd).gsub(/[^-x00-\x7F]/n, '').to_s.upcase,  a.rank.to_f]}
          @results.reverse!
        when "harvesting_date"
          @results.sort!{|a,b| b.date_indexed.to_f <=> a.date_indexed.to_f;  } 
      end
    end
    return @results
  end
  
  def image_tooltip
    @selected_image=nil
    id = params[:id]
    @selected_image=$objDispatch.GetId(id) 
    strip_quotes(@selected_image)
    if @selected_image==nil
      flash.now[:notice]=translate('IMAGE_NOT_FOUND')
    else
      render(:layout=>false)
    end
  end
   
  def show_citation
    id = params[:id]
    @record_for_citation=$objDispatch.GetId(id) 
    strip_quotes(@record_for_citation)
    @record_for_citation
    render(:layout=>false)  
  end
   
  def spell_check
  		_query					=	@query[0].to_s;
  		_query 					= _query.gsub(" or ", " ");
  		_query 					= _query.gsub(" and ", " ");
  		@spelling_list	= $objDispatch.spellCheck(_query);
  end        
  
  def cart
    begin
      paginate_cart(2)
    rescue
      logger.debug("no cookie found !")
    end
  end
  
  # The method return is array of string 
  # which contains relations associated at the keyword entered
  # this function must be called after finishsearch
  def see_also
    @seeAlso = []
    if !@query[0].blank?
      logger.debug("[see_also] query: #{@query[0]}")
      @seeAlso = $objDispatch.SeeAlso(@query[0]);
    end
  end
  
end
