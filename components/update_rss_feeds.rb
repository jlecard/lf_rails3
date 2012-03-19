RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)

if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'

class UpdateRssFeeds 
  require 'rubygems'
  require 'yaml'
  require 'iconv'
  
  def initialize()
    super
    @logger = ActiveRecord::Base.logger
  end
  
  def updateRssFeeds(rss_feed_id=0)
    begin
      # get rss feed properties
      if(rss_feed_id!=0)
        rss_feeds_to_update << RssFeed.getRssFeedById(rss_feed_id)
      else
        rss_feeds_to_update = UpdateRssFeeds.getRssFeedsToUpdate()
      end
      
      if(!rss_feeds_to_update.nil?)
        @logger.info("Begin update ...")
        @logger.info("To update : #{rss_feeds_to_update.inspect}")
        rss_feeds_to_update.each do |rf|
          # get cache search
          cs = CachedSearch.find_by_sql("SELECT cached_searches.id,cached_searches.query_string,cached_searches.query_type,cached_searches.max_recs FROM cached_searches, rss_feeds, primary_document_types where cached_searches.query_type='document_type' and cached_searches.query_string=primary_document_types.name and primary_document_types.id=#{rf.primary_document_type} ")
          if(!cs.nil? and !cs[0].nil?)
            id_collections = CollectionGroupMember.find_by_sql("SELECT DISTINCT(collection_id) FROM collection_group_members WHERE collection_group_id = #{rf.collection_group} ")
            # Delete cached_records by collection_id and search_id
            @logger.info("To update : #{id_collections.inspect}")
            id_collections.each do |idc|
              CachedRecord.delete_all(" search_id = #{cs[0].id} and collection_id = #{idc.collection_id} ")
            end
          end
          update_rss_feed_cached_records(rf,cs[0])
        end
        @logger.info("End update.")
      end
    rescue => e
      @logger.error("[UpdateRssFeeds] [updateRssFeeds] Error : #{e.message}")
      @logger.error("[UpdateRssFeeds] [updateRssFeeds] Error : #{e.backtrace.join("\n")}")
    end
  end
  
  def self.getRssFeedsToUpdate()
    rss_feeds_to_update = RssFeed.find_by_sql("SELECT * from rss_feeds where (DATE(current_date)-DATE(rss_feeds.created_at))%rss_feeds.update_periodicity=0")
    return rss_feeds_to_update
  end
  
  def update_rss_feed_cached_records(rss_feed,cached_search)
    begin
      
      if(!rss_feed.nil?)
        @operator=[]
        @logger.info("update_rss_feed_cached_records : #{rss_feed} cached_search : #{cached_search}")
        @operator << "AND"
        
        @sets = "g"+rss_feed.collection_group.to_s
        if (@sets.match("widget"))
          @sets= WIDGET_SETS;
        end
        
        @query=[]
        @type=[]
        @operator=[]
        
        if !cached_search.query_string.nil? and cached_search.query_string != 'None'
          @query << cached_search.query_string
          @type << cached_search.query_type
        end
        
        @start = "0"
        
        @max = cached_search.max_recs
        
        options = {}
        options["isbn"] = rss_feed.isbn_issn_nullable        
        options["news"] = rss_feed.new_docs        
        options["query"] = rss_feed.solr_request
        options["sort"] = ""
        
        # request
        ms = MetaSearch.new
        ids = ms.SearchAsync(@sets, @type, @query, @start, @max, @operator,options)
      else
        ids=[]
      end
      #loop through the ids to get info
      completed=[]
      errors=[]
      start_time=Time.now
      nbJobs = ids.length.to_i
      while ((completed.length.to_i+errors.length.to_i)<nbJobs) && ((Time.now-start_time)<RSS_TIMEOUT)
        sleep(0.5)
        
        items=ms.CheckJobStatus(ids)
        if !items.nil?
          items.each do |item|
            id = item.job_id
            
            # test if job is completed
            if !completed.include?(id)
              if item.status==JOB_ERROR
                if !errors.include?(id)
                  errors<<item.id
                  ids.delete(id)
                end
              elsif item.status==JOB_FINISHED
                completed<<id
                ids.delete(id)
              end
            end
          end
        end
      end
    end
  end
end

urf = UpdateRssFeeds.new

urf.updateRssFeeds
