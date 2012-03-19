require 'rubygems'
require 'cgi'

class EuropresseSearchClass < ActionController::Base
  
  
  attr_reader :hits, :xml, :total_hits
  @cObject = nil
  @pkeyword = ""
  @search_id = 0
  @hits = 0
  @total_hits = 0
  
  
  def self.query_string(type, keyword)
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
  
  def self.normalize(_string)
    return UtilFormat.normalize(_string) if _string != nil
    return ""
  end
  
  
  
  
  
  
  
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[EuroPressSearchClass][SearchCollection]")
    logger.debug("[EuroPressSearchClass][SearchCollection] _qstring.class = #{_qstring.class}")
    @cObject = _collect
    @pkeyword = query_string(_qtype, _qstring.join(" "))
    logger.debug("[EuroPressSearchClass][SearchCollection] @pkeyword = #{@pkeyword}")
    logger.debug("[EuroPressSearchClass][SearchCollection] @pkeyword.class = #{@pkeyword.class}")
    @search_id = _last_id
    _lrecord = Array.new()
    logger.debug("[EuropresseSearchClass][_qtype]======#{_qtype} ")
    
    begin
      #initialize
      logger.debug("COLLECT: " + _collect.host)
      
      login
      results = search(@pkeyword, _max.to_i)
      logout
      
      logger.debug("EuropresseSearchClass => Search performed")
      logger.debug("EuropresseSearchClass : #{results.length}/#{@total_hits}")
    rescue Exception => bang
      logger.debug("[EuropresseSearchClass] [SearchCollection] error: " + bang.message)
      logger.debug("[EuropresseSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
      if _action_type != nil
        _lxml = ""
        logger.debug("ID: " + _last_id.to_s)
        my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
        return my_id, 0
      else
        return nil
      end
    end
    
    if results != nil 
      begin
        _lrecord = parse_europresse(results, infos_user, _collect.id)
      rescue Exception => bang
        logger.error("[EuroPresseSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[EuroPresseSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
        if _action_type != nil
          _lxml = ""
          logger.debug("ID: " + _last_id.to_s)
          my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
          return my_id, 0, @total_hits
        else
          return nil
        end
      end
    end
    
    _lprint = false
    if _lrecord != nil
              ### Add cache record ####
      if (CACHE_ACTIVATE and job_id > 0)
        begin
          if infos_user and !infos_user.location_user.blank?
            cle = "#{job_id}_#{infos_user.location_user}"
          else
            cle = "#{job_id}"
          end
          CACHE.set(cle, _lrecord, 3600.seconds)
          logger.debug("[#{self.class}][SearchCollection] Records set in cache with key #{cle}.")
        rescue
          logger.error("[#{self.class}][SearchCollection] error when writing in cache")
        end
      end
      _lxml = CachedSearch.build_cache_xml(_lrecord)
      
      if _lxml != nil: _lprint = true end
      if _lxml == nil: _lxml = "" end
      
      #============================================
      # Add this info into the cache database
      #============================================
      if _last_id.nil?
        # FIXME:  Raise an error
        logger.debug("Error: _last_id should not be nil")
      else
        logger.debug("Save metadata")
        status = LIBRARYFIND_CACHE_OK
        if _lprint != true
          status = LIBRARYFIND_CACHE_EMPTY
        end
        my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, status, infos_user, @total_hits)
      end
    else
      logger.debug("save bad metadata")
      _lxml = ""
      logger.debug("ID: " + _last_id.to_s)
      my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
    end
    
    if _action_type != nil
      if _lrecord != nil
        return my_id, _lrecord.length, @total_hits
      else
        return my_id, 0, @total_hits
      end
    else
      return _lrecord
    end
  end
  
  
  
  
  
  
  
  
  
  
  ##TODO => replace by login(username, password) and store these in config
  def self.login
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
    puts result
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
  
  def self.search(text, max)
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
      
    rescue Exception => e
      logger.debug("[EuroPresse] : response => #{response}")
      logger.error("[EuroPresse] : error => #{e.message}")
      logger.debug("[EuroPresse] : backtrace => #{e.backtrace.join("\n")}")
    end
    logger.debug("================== SOAP REQUEST ================= \n#{data}\n")
    begin
      # Post the request
      resp, result = http.post(path, data, header)
    rescue Exception => e
      logger.error("[LextensoSearchClass][search] error: " + e.message)
      logger.error("[LextensoSearchClass][search] trace: " + e.backtrace.join("\n"))
    end
    
    doc = Nokogiri::XML.parse(result)
    doc.remove_namespaces!
    @total_hits=doc.xpath("////TotalDocFound").text
    return result
  end
  
  def self.logout
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
  
  def self.parse_europresse(records, infos_user, collection_id) 
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
        record.vendor_name = @cObject.alt_name
        record.availability = @cObject.availability
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
        record.id =  UtilFormat.html_decode(item.xpath(".//Name").text).gsub("·","").gsub("×","") + ";" + @cObject.id.to_s + ";" + @search_id.to_s
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
        record.vendor_url = @cObject.vendor_url
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
  
  def self.remove_kwic_format(text)
    logger.debug("[EuroPresseSearchClass][remove_kwic_format] text = #{text}")
    text = text.gsub(/<.+?>/i,"")
    logger.debug("[EuroPresseSearchClass][remove_kwic_format] text = #{text}")    
    return text
  end
  
  
end
