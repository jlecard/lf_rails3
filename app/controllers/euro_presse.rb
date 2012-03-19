require 'savon'
# gem install savon

class EuroPresse
  
  def initialize(proxy, logger)
    @identity = nil
    @logger = logger
    access_url = "http://ws.cedrom-sni.com/access.asmx?WSDL"
    search_url = "http://ws.cedrom-sni.com/search.asmx?WSDL"
    if proxy
      @access_client = Savon::Client.new access_url, :proxy => proxy
      @search_client = Savon::Client.new search_url, :proxy => proxy
    else
      @access_client = Savon::Client.new access_url
      @search_client = Savon::Client.new search_url
    end
  end
  
  ##TODO => replace by login(username, password) and store these in config
  def login
    if !@identity
      response = @access_client.login do |soap|
        body = Hash.new
        body["wsdl:Username"] = "pompi"
        body["wsdl:Password"] = "biblio"
        body["wsdl:Product_id"] = 8
        soap.body = body
      end
      @identity = response.to_hash[:login_response][:login_result]
      @logger.debug("[EuroPresse][login] identity = #{@identity}")
    end
  end
  
  # Search for text through webservices  
  # Returns total results and a result Hash with following keys : 
  # :title, 
  # :teaser, 
  # :program, 
  # :status_id, 
  # :length, 
  # :date, 
  # :broadcasting_time, 
  # :document_url, 
  # :authors, 
  # :attachments, 
  # :source, 
  # :hits, 
  # :name, 
  # :word_count, 
  # :relevance, 
  # :version, 
  # :document_language_id
  
  def search(text, max)
    @logger.debug("[EuroPresse][search] text = #{text} --- max = #{max}")
    login if !@identity
    begin
      response = @search_client.execute do |soap|
        body = Hash.new
        body["wsdl:Identity"] = @identity
        body["wsdl:DocBase_id"] = 1
        body["wsdl:SourceCodes"] = nil
        body["wsdl:Text"] = text
        body["wsdl:DefaultOperator"] = 1
        body["wsdl:DateRange_id"] = 4
        body["wsdl:DateStart"] = ""
        body["wsdl:DateEnd"] = ""
        body["wsdl:Sort_id"] = 1
        body["wsdl:MaxCount"] = max
        soap.body = body
      end
    rescue Exception => e
      @logger.debug("[EuroPresse] : response => #{response}")
      @logger.error("[EuroPresse] : error => #{e.message}")
      @logger.debug("[EuroPresse] : backtrace => #{e.backtrace.join("\n")}")
    end
    
    results = response.to_hash[:execute_response][:execute_result][:search_doc_info_items][:search_doc_info] 
    total_doc = response.to_hash[:execute_response][:execute_result][:search_result_info_items][:search_result_info][:total_doc_found]
    return results, total_doc
  end
  
  def logout
    response = @access_client.logout do |soap|
      body = Hash.new
      body["wsdl:Identity"] = @identity
      soap.body = body
    end
    @identity = nil
  end
end