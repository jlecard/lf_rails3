#encoding:utf-8

# generated file - BASIC Search Class skeleton


class <%=class_name%>SearchClass < ActionController::Base
  
  include SearchClassHelper
  attr_accessor :hits, :total_hits, :collection, :pkeyword, :search_id, :hits, :total_hits, :max
  
  def self.GetRecord(doc_id, collection_id, search_id, infos_user = nil)
    return CacheSearchClass.GetRecord(doc_id, collection_id, search_id, infos_user)
  end
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[<%=class_name%>SearchClass][SearchCollection]")
    @collection = _collect
    @action = _action_type
    @search_id = _last_id
    @records = []
    @pkeyword = _qstring.join(" ")
    @max = _max.to_i
    
    begin
      #initialize
      results = search
      logger.debug("<%=class_name%>SearchClass => Search performed")
      parse_records(results) if results
      logger.debug("<%=class_name%>SearchClass : #{results.length}/#{@total_hits}")
    rescue => bang
      logger.error("[<%=class_name%>SearchClass] [SearchCollection] error: " + bang.message)
      logger.debug("[<%=class_name%>SearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
    end
    save_in_cache
  end
  
  def search
    ### search code goes here : @pkeyword and @max are available for searching
    
  end
  
  def parse_records(results)
    ### parsing logic goes here 
    @records
  end
    
end
