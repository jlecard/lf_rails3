class Admin::RssFeedController < ApplicationController
  include ApplicationHelper
  include SearchHelper
  
  auto_complete_for :rss_feed, :name, {}
  auto_complete_for :rss_feed, :full_name, {}
  layout 'admin'
  before_filter :authorize, :except => 'login',
  :role => 'administrator',
  :msg => 'Access to this page is restricted.'
  
  
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = SearchTabFilter.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = SearchTab.load_groups;
    
    @primary_document_types = load_primary_document_types;
  end
  
  def index
    list
    render :action => 'list'
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  
  def list
    conditions = Array.new
    # Filter on the rss_feed               
    conditions.push("(name LIKE '#{params[:rss_feed][:name]}')") unless params[:rss_feed].nil? or params[:rss_feed][:name].blank?
    conditions.push("(full_name LIKE '#{params[:rss_feed][:full_name]}')") unless params[:rss_feed].nil? or params[:rss_feed][:full_name].blank?
    conditions.push("(primary_document_type LIKE '#{params[:primary_document_type]}')") unless params[:rss_feed].nil? or params[:primary_document_type].blank?
    conditions.push("(collection_group LIKE '#{params[:collection_group]}") unless params[:rss_feed].nil? or params[:collection_group].blank?
    
    @rss_feeds_pages, @rss_feeds = paginate :rss_feeds, :per_page => 20,:order => 'full_name asc', :conditions => conditions
    @display_columns = ['full_name', 'name', 'created_at', 'updated_at']
  end
  
  def load_primary_document_types
    return PrimaryDocumentType.find(:all);
  end
  
  def new
    @rss_feed = RssFeed.new
  end
  
  def show
    @rss_feed = RssFeed.find(params[:id])
  end
  
  def edit
    @rss_feed = RssFeed.find(params[:id])
  end
  
  def create
    @rss_feed = RssFeed.new(params[:rss_feed])
    if @rss_feed.save
      params[:rss_feed][:url] = "#{CFG_LF_URL_BASE}rss/feed?query[rss_id]=#{@rss_feed.id}"
      @rss_feed.url = params[:rss_feed][:url]
      @rss_feed.save
      flash[:notice] = translate('RSS_FEED_CREATED')
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def update
    @rss_feed = RssFeed.find(params[:id])
    if @rss_feed.update_attributes(params[:rss_feed])
      flash[:notice] = translate('RSS_FEED_UPDATED')
      redirect_to :action => 'show', :id => @rss_feed
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    Subscription.destroy_all(" obj_id = #{params[:id]} and obj = #{ENUM_RSS_FEED} ")
  
    RssFeed.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  # params required :
  #   query[string] = words search ex: word
  #   query[type] = field filter ex:keyword 
  #   query[max] = max results
  #   sets = collections group
  #   filter = filter facette ex:autor
  #   sort_value = sort ex:relevande
  def search
    begin
      logger.info("[RssFeedController] search : #{params.inspect}")
      init_search
      # stats
#      items = {:rss_url => "#{params.inspect}", :host => "#{request.remote_addr}"};
#      LogGeneric.addToFile("LogRssUsage", items)
      # log params
      logger.info("FEED TYPE: #{@type} Query: #{@query} Operator: #{@operator}")
      # request
      ids = $objDispatch.SearchAsync(@sets, @type, @query, @start, @max, @operator)
     # ids = $objDispatch.SearchAsync(@sets, @type, @query, @start, 20000, @operator)
      logger.info("[RssFeedController] jobs : #{ids.inspect}")
            
      #loop through the ids to get info
      completed=[]
      errors=[]
      start_time=Time.now
      nbJobs = ids.length.to_i
      while ((completed.length.to_i+errors.length.to_i)<nbJobs) && ((Time.now-start_time)<RSS_TIMEOUT)
        sleep(0.5)
        logger.info("[RssFeedController] jobs : #{ids.inspect}")
        logger.info("[RssFeedController] completed : #{completed.inspect}")
        logger.info("[RssFeedController] errors : #{errors.inspect}")
        items=$objDispatch.CheckJobStatus(ids)
        if !items.nil?
          items.each do |item|
            id = item.job_id
            logger.info("[RssController] item : #{id} => [status=#{item.status}]")
            # test if job is completed
            if !completed.include?(id)
              if item.status==JOB_ERROR
                if !errors.include?(id)
                  errors<<item.id
                  ids.delete(id)
                end
              elsif item.status==JOB_FINISHED
                logger.debug("completed: #{id}")
                completed<<id
                ids.delete(id)
              end
            end
          end
        end
      end
      @records =  $objDispatch.GetJobsRecords(completed, @max)
      
      if @records.nil?
        @records = []
      end
      
      t = RecordController.new()
      # set params to recordController
      t.build_results(@records, @sort_value, @filter)
      # call filter results      
      t.filter_results
      # get results to sort
      @records = t.sort_results
    rescue => e
      logger.error("[RssFeedController] error : #{e.message}")
      logger.error("[RssFeedController] error : #{e.backtrace.join("\n")}")
    end
    
    headers["Content-Type"] = "application/xml"
    render :layout =>false
    
  end
  
end