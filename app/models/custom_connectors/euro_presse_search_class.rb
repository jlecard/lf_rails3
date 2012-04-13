#encoding:utf-8
require 'rubygems'
require 'cgi'

class EuropresseSearchClass < ActionController::Base
  
  include SearchClassHelper
  attr_reader :hits, :xml, :total_hits
  @collection = nil
  @pkeyword = ""
  @search_id = 0
  @hits = 0
  @total_hits = 0
  
  
  def query_string(type, keyword)
    logger.debug("[EuroPressSearchClass][query_string] TYPE=#{type}")
    logger.debug("[EuroPressSearchClass][query_string] TYPECLASS=#{type.class}")
    case type.to_s
      when 'creator'
      return "AUT_BY=#{keyword}" 
      when 'title'
      return "LEAD=#{keyword}"
      when 'subject'
      return "SUJ_KW=#{keyword}"
      when 'theme'
      return "SUJ_KW=#{keyword}"
      when 'publisher'
      return "AUT_BY=#{keyword}" 
    else
      return keyword
    end
  end
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user));
  end
  
  def normalize(_string)
    return UtilFormat.normalize(_string) if _string != nil
    return ""
  end  
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[EuroPressSearchClass][SearchCollection]")
    logger.debug("[EuroPressSearchClass][SearchCollection] _qstring.class = #{_qstring.class}")
    @collection = _collect
    @action = _action_type
    @pkeyword = query_string(_qtype, _qstring.join(" "))
    logger.debug("[EuroPressSearchClass][SearchCollection] @pkeyword = #{@pkeyword}")
    logger.debug("[EuroPressSearchClass][SearchCollection] @pkeyword.class = #{@pkeyword.class}")
    @search_id = _last_id
    @max = _max.to_i
    @records = []
    logger.debug("[EuropresseSearchClass][_qtype]======#{_qtype} ")
    
    begin
      #initialize
      logger.debug("COLLECT: " + @collection.host)
      
      login
      results = search(@pkeyword, @max)
      logout
      
      logger.error("EuropresseSearchClass => Search performed")
      logger.debug("EuropresseSearchClass : #{results.length}/#{@total_hits}")
    rescue => bang
      logger.error("[EuropresseSearchClass] [SearchCollection] error: " + bang.message)
      logger.debug("[EuropresseSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
    end
    
    if results
      begin
        @records = parse_europresse(results, infos_user, _collect.id)
      rescue Exception => bang
        logger.error("[EuroPresseSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[EuroPresseSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
      end
    end
    save_in_cache
  end
  

  ##TODO => replace by login(username, password) and store these in config
  def login
    if !@identity
      
      header = {"Content-Type"=>"text/xml;charset=UTF-8",
      "Accept-Encoding"=>"gzip,deflate",
      "SOAPAction"=>"http://ws.cedrom-sni.com/Login",
      "User-Agent"=>"Jakarta Commos-HttpClient/3.1",
      "Host"=>"ws.cedrom-sni.com",
      "Proxy-Connection" => "Keep-Alive",
      "POST"=>"http://ws.cedrom-sni.com/access.asmx HTTP/1.1"}
      path = "access.asmx?WSDL"
      http = Net::HTTP::Proxy('spxy.bpi.fr',3128).new('ws.cedrom-sni.com/', 80)
      data = <<-EOF
              <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.cedrom-sni.com">
                <soapenv:Header/>
                <soapenv:Body>
                  <ws:Login>
                    <ws:Product_id>8</ws:Product_id>
                    <ws:Username>pompi</ws:Username>
                    <ws:Password>biblio</ws:Password>
                  </ws:Login>
                </soapenv:Body>
              </soapenv:Envelope>
              EOF
      
      
      logger.debug("================== SOAP REQUEST ================= \n#{data}\n")
      begin
        # Post the request
        resp, result = http.post(path, data, header)
      rescue Exception => e
        logger.error("[LextensoSearchClass][search] error: " + e.message)
        logger.error("[LextensoSearchClass][search] trace: " + e.backtrace.join("\n"))
      end
    end
    doc = Nokogiri::XML.parse(result)
    doc.remove_namespaces!
    @identity = doc.xpath(".//LoginResult").text
    logger.debug("[EuroPresse][login] identity = #{@identity}")
    
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
    logger.debug("[EuroPresse][search] text = #{text} --- max = #{max}")
    login if !@identity
    begin
      
      header = {"Content-Type"=>"text/xml;charset=UTF-8",
      "Accept-Encoding"=>"gzip,deflate",
      "SOAPAction"=>"http://ws.cedrom-sni.com/Execute",
      "User-Agent"=>"Jakarta Commos-HttpClient/3.1",
      "Host"=>"ws.cedrom-sni.com",
      "Proxy-Connection" => "Keep-Alive",
      "POST"=>"http://ws.cedrom-sni.com/search.asmx HTTP/1.1"}
      path = "search.asmx?WSDL"
      http = Net::HTTP::Proxy('spxy.bpi.fr',3128).new('ws.cedrom-sni.com/', 80)
      data = <<-EOF
              <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.cedrom-sni.com">
                 <soapenv:Header/>
                 <soapenv:Body>
                    <ws:Execute>
                       <ws:Identity>#{@identity}</ws:Identity>
                       <ws:DocBase_id>1</ws:DocBase_id>
                       <ws:SourceCodes></ws:SourceCodes>
                       <ws:Text>#{text}</ws:Text>
                       <ws:DefaultOperator_id>1</ws:DefaultOperator_id>
                       <ws:DateRange_id>4</ws:DateRange_id>
                       <ws:DateStart></ws:DateStart>
                       <ws:DateEnd></ws:DateEnd>
                       <ws:Sort_id>1</ws:Sort_id>
                       <ws:MaxCount>#{max}</ws:MaxCount>
                    </ws:Execute>
                 </soapenv:Body>
              </soapenv:Envelope>
              EOF
      
    rescue => e
      logger.debug("[EuroPresse] : response => #{response}")
      logger.error("[EuroPresse] : error => #{e.message}")
      logger.debug("[EuroPresse] : backtrace => #{e.backtrace.join("\n")}")
    end
    logger.debug("================== SOAP REQUEST ================= \n#{data}\n")
    begin
      # Post the request
      resp, result = http.post(path, data, header)
    rescue => e
      logger.error("[LextensoSearchClass][search] error: " + e.message)
      logger.error("[LextensoSearchClass][search] trace: " + e.backtrace.join("\n"))
    end
    doc = Nokogiri::XML.parse(result)
    doc.remove_namespaces!
    @total_hits=doc.xpath("////TotalDocFound").text
    p @total_hits
    return result
  end
  
  def logout
    header = {"Content-Type"=>"text/xml;charset=UTF-8",
      "Accept-Encoding"=>"gzip,deflate",
      "SOAPAction"=>"http://ws.cedrom-sni.com/Logout",
      "User-Agent"=>"Jakarta Commos-HttpClient/3.1",
      "Host"=>"ws.cedrom-sni.com",
      "Proxy-Connection" => "Keep-Alive",
      "POST"=>"http://ws.cedrom-sni.com/access.asmx HTTP/1.1"}
    path = "access.asmx?WSDL"
    http = Net::HTTP::Proxy('spxy.bpi.fr',3128).new('ws.cedrom-sni.com/', 80)
    data = <<-EOF
              <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.cedrom-sni.com">
                 <soapenv:Header/>
                 <soapenv:Body>
                    <ws:Logout>
                       <ws:Identity>#{@identity}</ws:Identity>
                    </ws:Logout>
                 </soapenv:Body>
              </soapenv:Envelope> 
              EOF
    resp, result = http.post(path, data, header)
    
    @identity = nil
  end
  
  def parse_europresse(records, infos_user, collection_id) 
    logger.debug("[EuroPresseSearchClass][parse_europress] Entering method...")
    _objRec = RecordSet.new()
    _record = Array.new()
    _x = 0
    
    _start_time = Time.now()
    
    if records.class == String
      records = Nokogiri::XML.parse(records)
      records.remove_namespaces!
    end
    _start_time = Time.now()
    
    nodes = records.xpath("///SearchDocInfo")
    #@total_hits = nodes.length
    @hits = nodes.length
    
    nodes.each  { |item|
      logger.debug("EuroPresseSearchClass][parse_europresse] looping through items...")
      logger.debug("#{item.inspect}")
      begin
        _title = item.xpath(".//Title").text
        logger.debug("Title: " + _title) if _title
        next if !_title
        _authors = item.xpath(".//Author").text
        _description = remove_kwic_format(item.xpath(".//Teaser").text)
        _subjects = _title
        _link = item.xpath(".//DocumentUrl").text
        _keyword = _title + " " + _description
        _date = item.xpath(".//Date").text
        _source = item.xpath(".//Source").text
        record = Record.new()
        
        record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
        logger.debug("past rank")
        record.vendor_name = @collection.alt_name
        record.availability = @collection.availability
        record.ptitle = _title
        record.title =  _title
        record.atitle =  _title
        record.issue_title = _source
        record.issn =  ""
        record.isbn = ""
        record.abstract = _description
        record.date = _date
        record.author = _authors
        record.link = ""
        record.id =  UtilFormat.html_decode(item.xpath(".//Name").text).gsub("·","").gsub("×","") + ";" + @collection.id.to_s + ";" + @search_id.to_s
        record.doi = ""
        record.openurl = ""
        if(INFOS_USER_CONTROL and !infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(infos_user,collection_id)
          if(droits.id_perm == ACCESS_ALLOWED)
            record.direct_url = "http://www.bpe.europresse.com/WebPages/Search/Doc.aspx?DocName=#{CGI::escape(item.xpath(".//Name").text)}&ContainerType=SearchResult"
          else
            record.direct_url = "";
          end
        else
          record.direct_url = "http://www.bpe.europresse.com/WebPages/Search/Doc.aspx?DocName=#{CGI::escape(item.xpath(".//Name").text)}&ContainerType=SearchResult"          
        end
        
        record.static_url = _link
        record.subject = _title
        record.publisher = _source
        record.vendor_url = @collection.vendor_url
        record.material_type = "Article"
        record.volume = ""
        record.issue = ""
        record.page = "" 
        record.number = ""
        record.callnum = ""
        ##TODO: use language code to retrieve language label using WebService 
        record.lang = item.xpath(".//DocumentLanguage_id").text
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.hits = @hits
        _record[_x] = record
        _x = _x + 1
      rescue Exception => bang
        logger.error("[EuropresseSearchClass][parse] error: " + bang)
        logger.error("[EuropresseSearchClass][parse] trace: " + bang.backtrace.join("\n"))
        next
      end
    }
    return _record 
    
  end
  
  def remove_kwic_format(text)
    logger.debug("[EuroPresseSearchClass][remove_kwic_format] before text = #{text}")
    text = text.gsub(/<.+?>/i,"")
    logger.debug("[EuroPresseSearchClass][remove_kwic_format] after text = #{text}")    
    return text
  end
  
  
end
