require 'rubygems'
require 'net/http'
require 'cgi'
require 'nokogiri'

class LextensoSearchClass < ActionController::Base
  attr_reader :hits, :total_hits
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil ,options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[lextenso_search_class][SearchCollection] entered")
    @cObject = _collect
    @pkeyword = _qstring.join(" ")
    @search_id = _last_id
    _lrecord = Array.new()
    
    begin
      #initialize
      logger.debug("COLLECTION: " + _collect.host)
      
      #perform the search
      results = search(@pkeyword, _max)      
      logger.debug("lextenso_search_class][SearchCollection]Search performed")
      logger.debug("lextenso_search_class][SearchCollection]RESPONSE: " + results.to_s)
    rescue Exception => bang
      logger.error("lextenso_search_class][SearchCollection] [SearchCollection] error: " + bang.message)
      logger.error("lextenso_search_class][SearchCollection] [SearchCollection] trace:" + bang.backtrace.join("\n"))
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
        _lrecord = parse_results(results, infos_user)
      rescue Exception => bang
        logger.error("[LextensoSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[LextensoSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
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
      _lxml = CachedSearch.build_cache_xml(_lrecord)
      _lprint = true if _lxml != nil
      _lxml = "" if _lxml == nil
      
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
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user));
  end
  
  def self.search(keyword, max)
    
    header = {"Content-Type"=>"text/xml;charset=UTF-8",
      "Accept-Encoding"=>"gzip,deflate",
      "SOAPAction"=>"",
      "User-Agent"=>"Jakarta Commos-HttpClient/3.1",
      "Host"=>"web-lextenso-test.jouve-hdi.com",
      "POST"=>"http://www.web-lextenso-test.jouve-hdi.com/lextenso-ws/serviceHTTP/1.1"}
    path = "lextenso-ws/lextenso-service.wsdl"
    http = Net::HTTP::Proxy('spxy.bpi.fr',3128).new('web-lextenso-test.jouve-hdi.com/', 80)
    data = <<-EOF
              <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mes="http://www.lextenso.fr/schemas/messages">
                 <soapenv:Header/>
                 <soapenv:Body>
                    <mes:findItemsRequest>
                       <mes:criteria>#{keyword}</mes:criteria>
                       <mes:start>1</mes:start>
                      <mes:maxResults>#{max}</mes:maxResults>
                    </mes:findItemsRequest>
                 </soapenv:Body>
              </soapenv:Envelope>
              EOF
    puts("================== SOAP REQUEST ================= \n#{data}\n")
    begin
      # Post the request
      resp, result = http.post(path, data, header)
    rescue Exception => e
      logger.error("[LextensoSearchClass][search] error: " + e.message)
      logger.error("[LextensoSearchClass][search] trace: " + e.backtrace.join("\n"))
    end
    
    return result
  end
  
  def self.parse_results(doc, infos_user)
    _objRec = RecordSet.new()
    _title = ""
    _authors = ""
    _description = ""
    _subjects = ""
    _record = Array.new()
    _x = 0
    if doc.class == String
      doc = Nokogiri::XML.parse(doc)
      doc.remove_namespaces!
    end
    _start_time = Time.now()
    
    nodes = doc.xpath("//item")
    @total_hits = nodes.length
    @hits = nodes.length
    
    nodes.each  { |item|
      #_title = UtilFormat.html_decode(item.xpath(".//title").text)
      _title = item.xpath(".//title").text
      next if !_title
      #_authors = UtilFormat.html_decode(item.xpath(".//author").text) if item.xpath(".//author")
      _authors = item.xpath(".//author").text
      #_type = UtilFomat.html_decode(item.xpath(".//type").text)
      _type = item.xpath(".//type").text
      #_keyword = normalize(_title) + " " + normalize(_description) + " "  + normalize(_subjects)
      _keyword = _objRec.normalize(_title) + " " + _objRec.normalize(_authors)
      _date = item.xpath(".//date").text
      record = Record.new()
      
      record.rank = _objRec.calc_rank({'title' => _objRec.normalize(_title), 'creator'=>_objRec.normalize(_authors), 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
      record.vendor_name = @cObject.alt_name
      record.ptitle = _objRec.normalize(_title)
      record.title =  record.ptitle
      record.atitle =  ""
      record.issn =  ""
      record.isbn = ""
      record.abstract = ""
      record.date = ""
      record.date = _date
      record.author = ""
      record.author = _authors
      record.link = ""
      rec_id =  item.xpath(".//id").text
      record.id = "#{rec_id};#{@cObject.id.to_s};#{@search_id.to_s}"
      record.doi = ""
      record.openurl = ""
      if(INFOS_USER_CONTROL and !infos_user.nil?)
        # Does user have rights to view the notice ?
        droits = ManageDroit.GetDroits(infos_user,@cObject.id)
        if(droits.id_perm == ACCESS_ALLOWED)
          record.direct_url = "http://www.lextenso.fr/weblextenso/article/afficher?id=#{rec_id}"
        else
          record.direct_url = "";
        end
      else
        record.direct_url = "http://www.lextenso.fr/weblextenso/article/afficher?id=#{rec_id}"          
      end
      
      record.static_url = @cObject.vendor_url
      record.subject = ""
      record.publisher = ""
      record.vendor_url = ""
      record.material_type = @cObject.mat_type
      record.rights = ""
      record.thumbnail_url = ""
      record.volume = ""
      record.issue = ""
      record.page = "" 
      record.number = ""
      record.callnum = ""
      record.lang = ""
      record.start = _start_time.to_f
      record.end = Time.now().to_f
      record.hits = @hits
      _record[_x] = record
      _x = _x + 1
    }
    
    return _record 
    
  end
  
end
