require 'rubygems'
require 'net/http'
require 'cgi'
require 'nokogiri'

class LextensoSearchClass < ActionController::Base
  include SearchClassHelper
  attr_reader :hits, :total_hits
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil ,options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[lextenso_search_class][SearchCollection] entered")
    @collection = _collect
    @pkeyword = _qstring.join(" ")
    @search_id = _last_id
    @records = []
    @action = _action_type
    
    begin
      #initialize
      logger.debug("COLLECTION: " + _collect.host)
      
      #perform the search
      results = search(@pkeyword, _max)      
      logger.debug("lextenso_search_class][SearchCollection]Search performed")
      logger.debug("lextenso_search_class][SearchCollection]RESPONSE: " + results.to_s)
    rescue => bang
      logger.error("lextenso_search_class][SearchCollection] [SearchCollection] error: " + bang.message)
      logger.error("lextenso_search_class][SearchCollection] [SearchCollection] trace:" + bang.backtrace.join("\n"))
    end
    
    if results
      begin
        @records = parse_results(results, infos_user)
      rescue => bang
        logger.error("[LextensoSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[LextensoSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
      end
    end
    
    save_in_cache
  end
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user));
  end
  
  def search(keyword, max)
    
    header = {"Content-Type"=>"text/xml;charset=UTF-8",
      "Accept-Encoding"=>"gzip,deflate",
      "SOAPAction"=>"",
      "User-Agent"=>"Jakarta Commos-HttpClient/3.1",
      "Host"=>"web-lextenso-test.jouve-hdi.com",
      "POST"=>"http://www.web-lextenso-test.jouve-hdi.com/lextenso-ws/serviceHTTP/1.1"}
    path = "lextenso-ws/lextenso-service.wsdl"
    if proxy?
      http = Net::HTTP::Proxy(@proxy_host,@proxy_port).new('web-lextenso-test.jouve-hdi.com/', 80)
    else
      http = Net::HTTP.new('web-lextenso-test.jouve-hdi.com/', 80)
    end
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
    rescue => e
      logger.error("[LextensoSearchClass][search] error: " + e.message)
      logger.error("[LextensoSearchClass][search] trace: " + e.backtrace.join("\n"))
    end
    
    return result
  end
  
  def parse_results(doc, infos_user)
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
      record.vendor_name = @collection.alt_name
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
      record.id = "#{rec_id};#{@collection.id.to_s};#{@search_id.to_s}"
      record.doi = ""
      record.openurl = ""
      if(INFOS_USER_CONTROL and !infos_user.nil?)
        # Does user have rights to view the notice ?
        droits = ManageDroit.GetDroits(infos_user,@collection.id)
        if(droits.id_perm == ACCESS_ALLOWED)
          record.direct_url = "http://www.lextenso.fr/weblextenso/article/afficher?id=#{rec_id}"
        else
          record.direct_url = "";
        end
      else
        record.direct_url = "http://www.lextenso.fr/weblextenso/article/afficher?id=#{rec_id}"          
      end
      
      record.static_url = @collection.vendor_url
      record.subject = ""
      record.publisher = ""
      record.vendor_url = ""
      record.material_type = @collection.mat_type
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
