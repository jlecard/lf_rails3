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

class RssController < ApplicationController
  include SearchHelper
  
  # params required :
  #   query[string] = words search ex: word
  #   query[type] = field filter ex:keyword 
  #   query[max] = max results
  #   sets = collections group
  #   filter = filter facette ex:autor
  #   sort_value = sort ex:relevande
  def search
    begin
      logger.info("[RssController] search : #{params.inspect}")
      init_search
      # stats
#      items = {:rss_url => "#{params.inspect}", :host => "#{request.remote_addr}"};
#      LogGeneric.addToFile("LogRssUsage", items)
      # log params
      logger.info("FEED TYPE: #{@type} Query: #{@query} Operator: #{@operator}")
      
      # recherche les nouveautés
      options = {"isbn" => 0, "news" => 0, "query" => "", "sort" => "harvesting_date"}
       
      # request
      ids = $objDispatch.SearchAsync(@sets, @type, @query, @start, @max, @operator, options)
      logger.info("[RssController] jobs : #{ids.inspect}")
      
      #loop through the ids to get info
      completed=[]
      errors=[]
      start_time=Time.now
      nbJobs = ids.length.to_i
      while ((completed.length.to_i+errors.length.to_i)<nbJobs) && ((Time.now-start_time)<RSS_TIMEOUT)
        sleep(0.5)
        logger.fatal("[RssController] jobs : #{ids.inspect}")
        logger.fatal("[RssController] completed : #{completed.inspect}")
        logger.fatal("[RssController] errors : #{errors.inspect}")
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
              elsif item.status==JOB_FINISHED or item.status==JOB_PRIVATE
                logger.debug("completed: #{id}")
                completed<<id
                ids.delete(id)
              end
            end
          end
        end
      end
      @records =  $objDispatch.GetJobsRecords(completed, @max, nil)
      
      if @records.nil?
        @records = []
      end
      
      t = RecordController.new();
      @sort_value = "harvesting_date" 
      # set params to recordController
      t.setResults(@records, @sort_value, @filter);
      # call filter results      
      t.filter_results;
      # get results to sort
      @records = t.sort_results;
    rescue => e
      logger.error("[RssController] error : #{e.message}")
      logger.error("[RssController] error : #{e.backtrace.join("\n")}")
    end
    
    headers["Content-Type"] = "application/xml"
    render :layout =>false
    
  end
  
  def feed
    begin
      logger.info("[RssController] feed : #{params[:query][:rss_id]}")
      @title = ""
      rss_feed = RssFeed.find(:first, :conditions => " id = #{params[:query][:rss_id].to_i}")
      
      if(!rss_feed.nil?)
        
        @title = rss_feed.full_name
        params[:sets] = "g"+rss_feed.collection_group.to_s
      
        params[:query][:string] = "";
        params[:query][:type] = "";
        
        logger.info("[RssController] rss_feed.primary_document_type : #{rss_feed.primary_document_type}")
        if rss_feed.primary_document_type != 1 # correspond à NONE
          params[:query][:string] = PrimaryDocumentType.getPrimaryDocumentTypeNameById(rss_feed.primary_document_type)
          params[:query][:type] = "document_type"
        end
     
        options = {}
        options["isbn"] = rss_feed.isbn_issn_nullable        
        options["news"] = rss_feed.new_docs        
        options["query"] = rss_feed.solr_request
        options["sort"] = ""
        
        init_search
    
        # request
        CachedRecord.deleteCachedRecord(@query,@type,rss_feed.collection_group)
        ids = $objDispatch.SearchAsync(@sets, @type, @query, @start, @max, @operator,options)
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
        logger.info("[RssController] jobs : #{ids.inspect}")
        logger.info("[RssController] completed : #{completed.inspect}")
        logger.info("[RssController] errors : #{errors.inspect}")
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
              elsif item.status==JOB_FINISHED or item.status == JOB_PRIVATE
                logger.debug("completed: #{id}")
                completed<<id
                ids.delete(id)
              end
            end
          end
        end
      end
      @records =  $objDispatch.GetJobsRecords(completed, @max, nil)
      
      if @records.nil?
        @records = []
      end
      
      t = RecordController.new();
      # set params to recordController
      t.setResults(@records, @sort_value, @filter);
      # call filter results      
      t.filter_results;
      # get results to sort
      @records = t.sort_results;
    rescue => e
      logger.error("[RssController] error : #{e.message}")
      logger.error("[RssController] error : #{e.backtrace.join("\n")}")
    end
    
    headers["Content-Type"] = "application/xml"
    render :layout =>false
    
  end

end