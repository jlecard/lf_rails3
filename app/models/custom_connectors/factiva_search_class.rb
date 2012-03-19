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



require 'rubygems'
require 'net/http'
require 'cgi'


class FactivaSearchClass < ActionController::Base
  
  attr_reader :hits, :xml, :total_hits
  @cObject = nil
  @pkeyword = ""
  @search_id = 0
  @hits = 0
  @total_hits = 0
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil ,options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[factiva_search_class][SearchCollection] entered")
    @cObject = _collect
    @pkeyword = _qstring.join(" ")
    @search_id = _last_id
    _lrecord = Array.new()
    
    begin
      #initialize
      logger.debug("COLLECTION: " + _collect.host)
      
      #perform the search
      results = search(@pkeyword, _max, @cObject)
      logger.debug("factiva_search_class][SearchCollection]Search performed")
    rescue Exception => bang
      logger.error("factiva_search_class][SearchCollection] [SearchCollection] error: " + bang.message)
      logger.error("factiva_search_class][SearchCollection] [SearchCollection] trace:" + bang.backtrace.join("\n"))
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
        logger.error("[FactivaSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[FactivaSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
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
  
  # search records (max search = 100 and search by multiple of 10)
  def self.search(keyword, max,_collect)
    continue = false
    remaining = 0
    loops = 1
    if max > 100
      remaining = max%100
      raise "max. rows must be a multiple of 10" if max%10 != 0 
      continue = true
      loops = max/100
      max = 100
    end
    logger.debug("[FactivaSeachClass] [search] remaining = #{remaining} \n loops = #{loops}")
      host = ""
      port = ""
      if (_collect.proxy == 1)
        yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
        host             = yp['PROXY_HTTP_ADR']
        port             = yp['PROXY_HTTP_PORT']
        http = Net::HTTP::Proxy(host,port.to_i).new('developer.beta.factiva.com', 80)
      else
        http = Net::HTTP.new('developer.beta.factiva.com', 80)
      end
      
      header = {"soapAction"=>"urn:factiva:developer:v3_0/PerformContentSearch",
      "Content-Type"=>"text/xml; charset=utf-8"}
      path = "/3.0/search/search.asmx"
      
      data = <<-EOF
              <soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>
                <soap:Body>
                  <PerformContentSearch xmlns='urn:factiva:developer:v3_0:parsers'>
                    <controlData><![CDATA[UID=bpifdk&PWD=factiva&NS=16]]></controlData>
                    <searchString>#{keyword}</searchString>
                    <maxResultsToReturn>#{max}</maxResultsToReturn>
                    <sortOrder>Relevance</sortOrder>
                  </PerformContentSearch>
                </soap:Body>
              </soap:Envelope>
              EOF
      logger.debug("================== SOAP REQUEST ================= \n#{data}\n")
      begin      
        # Post the request
        resp, data = http.post(path, data, header)
      rescue Exception => e
        logger.error("[FactivaSearchClass][search] error: " + e.message)
        logger.error("[FactivaSearchClass][search] trace: " + e.backtrace.join("\n"))
      end
      context = search_context(data)
      threads = []
      mutexes = []
      i = 1
      j = 0
      if continue
        
        begin
          logger.debug("[FactivaSeachClass] [multithreading] #{loops} loops to process")
          while i < loops
            mutexes << Mutex.new
            mutexes[i-1].lock
            threads << Thread.new(i, context) do |i, context|
              j = i
              Thread.current["mycount"] = j
              Thread.current["context"] = context
              logger.debug("[FactivaSeachClass] [multithreading] Thread.current  = #{Thread.current["mycount"]}")
              logger.debug("[FactivaSeachClass] [multithreading] search_context = #{context}")
              sleep(Thread.current["mycount"])
              result = FactivaSearchClass::continue_search(context, Thread.current["mycount"])
              Thread.current["data"] = result
              mutexes[Thread.current["mycount"] - 1].lock
              #next
            end
            logger.debug("[FactivaSeachClass] [multithreading] loop # #{i}")
            i += 1
          end
          logger.debug("[FactivaSeachClass] [multithreading] Got #{threads.length} threads... Joining")
          y = 0
          threads.each do |t|
            mutexes[y].unlock
            t.join
            data = merge_doc(t["data"], data)
            logger.debug("[FactivaSeachClass] [multithreading] data has now #{data.xpath('//contentHeadline').length} nodes")
            logger.debug("[FactivaSeachClass] [multithreading] executed thread #{t["mycount"]}")
            y += 1
          end
        rescue Exception => e
          logger.error("[FactivaSeachClass] [search] error : #{e.message}.")
          logger.error("[FactivaSeachClass] [search] error : #{e.backtrace.join("\n")}.")
        end
      end
      if remaining > 0
        result = continue_search(context, i, remaining)
        data = merge_doc(result, data)
      end
      return data
    end
    
    def self.search_context(xml)
      doc = Nokogiri::XML.parse(xml)
      doc.remove_namespaces!
      context = doc.xpath("//searchContext").text
      return context
    end
    
    def self.continue_search(context, loop, modulo=0)
      logger.debug("[FactivaSearchClass][continue_search] called for loop # #{loop}")
      logger.debug("[FactivaSearchClass][continue_search] called with context = #{context}")
      first_result = loop*100
      max = 100
      if modulo != 0
        max = modulo  
      end
      header = {"soapAction"=>"urn:factiva:developer:v3_0/ContinueContentSearch",
      "Content-Type"=>"text/xml; charset=utf-8"}
      path = "/3.0/search/search.asmx"
      http = Net::HTTP::Proxy('spxy.bpi.fr',3128).new('developer.beta.factiva.com', 80)
      
      data = <<-EOF
      <soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>
        <soap:Body>
          <ContinueContentSearch xmlns='urn:factiva:developer:v3_0:parsers'>
            <controlData><![CDATA[UID=bpifdk&PWD=factiva&NS=16]]></controlData>
            <searchContext>#{context}</searchContext>
            <maxResultsToReturn>#{max}</maxResultsToReturn>
            <firstResultToReturn>#{first_result}</firstResultToReturn>
          </ContinueContentSearch>
        </soap:Body>
      </soap:Envelope>
    EOF
      
      # Post the request
      begin
        resp, data = http.post(path, data, header)
      rescue Exception => e
        logger.error("[FactivaSearchClass][continue_search] e.message")
        logger.debug("[FactivaSearchClass][continue_search] e.backtrace")
      end
      return data
    end
    
    def self.merge_doc(to_append, source)
      #logger.debug("[FactivaSearchClass][merge_doc] to_append = #{to_append}")
      doc_to_append = Nokogiri::XML.parse(to_append)
      if source.class == String
        source = Nokogiri::XML.parse(source)
        source.remove_namespaces!
      end
      doc_to_append.remove_namespaces!
      nodes_to_copy = doc_to_append.xpath(".//contentHeadline")
      logger.debug("[FactivaSearchClass][merge_doc] original source has #{source.xpath("//contentHeadline").length} nodes")
      logger.debug("[FactivaSearchClass][merge_doc] appending #{nodes_to_copy.length} nodes")
      #source_nodes = doc_source.xpath(".//contentHeadline") 
      nodes_to_copy.each do |n|
        source.root.add_child(n)
      end
      logger.debug("[FactivaSearchClass][merge_doc] merged source has #{source.xpath("//contentHeadline").length} nodes")
      return source
    end
    
    def self.parse_results(doc, infos_user) 
      begin
        logger.debug("[FactivaSearchClass][parse_results] Entering method...")
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
        #logger.debug("[FactivaSearchClass][parse_results] doc inspect : #{doc.inspect}")
        logger.debug("[FactivaSearchClass][parse_results] docclass : #{doc.class}")
        _start_time = Time.now()
        #logger.debug("[FactivaSearchClass][parse_results] doc : #{doc.length}")
        _hit_count = doc.xpath("//queryHitCount").text
        logger.debug("[FactivaSearchClass][parse_results] hit_count : #{_hit_count}")
        @total_hits = _hit_count.to_i
        nodes = doc.xpath("//contentHeadline")
        logger.debug("[FactivaSearchClass][parse_results] nodes : #{nodes.length}")
        ####### Prevent nokogiri going segfault (???) - temp until proper fixing #######
        logger.debug("[FactivaSearchClass] Node 102: " + nodes[102]) if nodes.length > 102
        ################################################################################
        @hits = nodes.length
        logger.debug("[FactivaSearchClass] Number of results: " + nodes.length.to_s)
        nodes.each  { |item|
          begin
            _title = UtilFormat.html_decode(item.xpath("./headline/paragraph").text)
            logger.debug("Title: " + _title) if _title
            next if !_title
            _authors = UtilFormat.html_decode(item.xpath("./byline").text) if item.xpath("./byline") 
            _description = UtilFormat.html_decode(item.xpath("./snippet/paragraph").text)
            _subjects = UtilFormat.html_decode(item.xpath("./sectionName").text) if item.xpath("./sectionName")
            _link = 
            _keyword = normalize(_title) + " " + normalize(_description) + " "  + normalize(_subjects)
            _date = item.xpath("./publicationDate").text
            _source = item.xpath("./sourceName").text
            record = Record.new()
            
            
            record.rank = _objRec.calc_rank({'title' => normalize(_title), 'creator'=>normalize(_authors), 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
            logger.debug("past rank")
            record.vendor_name = @cObject.alt_name
            record.ptitle = normalize(_title)
            record.title =  normalize(_title)
            record.atitle =  
            record.issn =  ""
            record.isbn = ""
            record.abstract = normalize(_description)
            record.date = normalize(_date)
            record.author = normalize(_authors)
            record.link = normalize(@cObject.vendor_url)
            rec_id =  item.xpath("./accessionNo").text
            record.id = "#{rec_id};#{@cObject.id.to_s};#{@search_id.to_s}"
            record.doi = ""
            record.openurl = ""
            if(INFOS_USER_CONTROL and !infos_user.nil?)
              # Does user have rights to view the notice ?
              droits = ManageDroit.GetDroits(infos_user,@cObject.id)
              if(droits.id_perm == ACCESS_ALLOWED)
                record.direct_url = "#{@cObject.vendor_url}/aa/?ref=#{rec_id}"
              else
                record.direct_url = "";
              end
            else
              record.direct_url = "#{@cObject.vendor_url}/aa/?ref=#{rec_id}"          
            end
            
            record.static_url = @cObject.vendor_url
            record.subject = normalize(_subjects)
            record.publisher = normalize(_source)
            logger.debug("[FactivaSearchClass] [parse] Record label = #{record.publisher}")
            record.vendor_url = normalize(@cObject.vendor_url)
            record.material_type = @cObject.mat_type # item.xpath("./contentParts")['contentType']
            record.rights = item.xpath("./copyright").text
            record.thumbnail_url = "http://logos.factiva.com/factcpLogo.gif"
            record.volume = ""
            record.issue = ""
            record.page = "" 
            record.number = ""
            record.callnum = ""
            record.lang = UtilFormat.normalizeLang(item.xpath("./baseLanguage").text)
            record.start = _start_time.to_f
            record.end = Time.now().to_f
            record.hits = @hits
            _record[_x] = record
            _x = _x + 1
          rescue Exception => e
            logger.error("[FactivaSearchClass][parse] error: " + e)
            logger.error("[FactivaSearchClass][parse] trace: " + e.backtrace.join("\n"))
            next
          end
        }
        logger.debug("[FactivaSearchClass]Finished _record array")
        return _record
      rescue Exception => e
        logger.error("[FactivaSearchClass][parse_results] error #{e.message}")
        logger.error("[FactivaSearchClass][parse_results] error #{e.backtrace}")
      end
      
    end
    
    def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
      return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user));
    end
    
    def self.normalize(_string)
      return UtilFormat.normalize(_string) if _string != nil
      return ""
      #_string = _string.gsub(/\W+$/,"")
      #return _string
    end
    
  end
  
  
  #<article number="2" type="revue" lang="FR"><title>Virus émergents ou menaces à répétition</title><year>2005</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>7</volume><number>2</number></source><pertinence>99</pertinence><authors>B. Lina</authors><link>http://www.emc-consulte.com/article/77669</link></article><article number="4" type="revue" lang="fr"><title>Émergences et barrières d'espèces</title><year>2004</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>34</volume><number>11</number></source><pertinence>98</pertinence><authors>A. Vabret</authors><link>http://www.emc-consulte.com/article/28153</link></article><article number="5" type="revue" lang="fr"><title>La grippe saisonnière</title><year>2010</year><source><label>Pathologie Biologie</label><nom>Pathologie Biologie</nom><volume>58</volume><number>2</number></source><pertinence>98</pertinence><authors>A. Vabret, J. Dina, D. Cuvillon-Nimal, E. Nguyen, S. Gouarin, J. Petitjean, J. Brouard, F. Freymuth</authors><link>http://www.emc-consulte.com/article/249607</link></article><article number="6" type="revue" lang="fr"><title>Virus Polyoma nouvellement découverts</title><year>2008</year><source><label>Pathologie Biologie</label><nom>Pathologie Biologie</nom><volume>57</volume><number>2</number></source><pertinence>98</pertinence><authors>H. Laude, P. Lebon</authors><link>http://www.emc-consulte.com/article/202068</link></article><article number="7" type="revue" lang="FR"><title>Le point sur l'infection par le virus West Nile</title><year>2001</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>3</volume><number>4</number></source><pertinence>98</pertinence><authors></authors><link>http://www.emc-consulte.com/article/77501</link></article><article number="8" type="revue" lang="fr"><title>Originalité des inhibiteurs d'entrée</title><year>2009</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>39</volume><number>10S1</number></source><pertinence>98</pertinence><authors>J. Izopet</authors><link>http://www.emc-consulte.com/article/228917</link></article><article number="9" type="revue" lang="fr"><title>Particularités épidémiologiques et prévention des infections nosocomiales virales</title><year>2008</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>11</volume><number>1</number></source><pertinence>97</pertinence><authors>O. Traor&amp;#x00E9;, C. Aumeran, C. Henquell</authors><link>http://www.emc-consulte.com/article/200739</link></article><article number="10" type="traite" lang="fr"><title>Virus syncytial respiratoire et virus para-influenza humains : épidémiologie</title><year>2003</year><source><label>Pédiatrie - Maladies infectieuses</label><nom>Pédiatrie - Maladies infectieuses</nom><fascicule>4-285-A-05</fascicule></source><pertinence>97</pertinence><authors>F. Freymuth</authors><link>http://www.emc-consulte.com/article/24105</link></article><article number="11" type="traite" lang="fr"><title>Virus respiratoire syncytial, métapneumovirus et virus para-influenza humains : propriétés des virus, multiplication, épidémiologie</title><year>2007</year><source><label>Pédiatrie - Maladies infectieuses</label><nom>Pédiatrie - Maladies infectieuses</nom><fascicule>4-285-A-05</fascicule></source><pertinence>97</pertinence><authors>F. Freymuth</authors><link>http://www.emc-consulte.com/article/58411</link></article><article number="12" type="revue" lang="en"><title>Amino acid and codon use: in two influenza viruses and three hosts</title><year>2007</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>37</volume><number>6</number></source><pertinence>97</pertinence><authors>C. Scapoli, S. De Lorenzi, G. Salvatorelli, I. Barrai</authors><link>http://www.emc-consulte.com/article/64394</link></article><article number="13" type="traite" lang="fr"><title>Poxvirus</title><year>2002</year><source><label>Biologie clinique</label><nom>Biologie clinique</nom><fascicule>90-55-0080</fascicule></source><pertinence>97</pertinence><authors>Antoine Garbarg Chenon, Jean-Claude Nicolas</authors><link>http://www.emc-consulte.com/article/61421</link></article><article number="14" type="revue" lang="fr"><title>Aspects urologiques de l'infection à &lt;i&gt;Polyomavirus&lt;/i&gt;</title><year>2009</year><source><label>Progrès en Urologie</label><nom>Progrès en Urologie</nom><volume>20</volume><number>1</number></source><pertinence>97</pertinence><authors>M. Thoulouzan, M. Courtade-Saidi, N. Kamar, L. Bellec, E. Huyghe, M. Souli&amp;#x00E9;, P. Plante</authors><link>http://www.emc-consulte.com/article/238858</link></article><article number="15" type="traite" lang="fr"><title>Hépatites d'étiologie inconnue</title><year>2004</year><source><label>Hépatologie</label><nom>Hépatologie</nom><fascicule>7-015-B-59</fascicule></source><pertinence>97</pertinence><authors>I. Chemin, P. Merle, R. Parana, C. Trepo</authors><link>http://www.emc-consulte.com/article/25618</link></article><article number="16" type="revue" lang="FR"><title>Virus de l'hépatite C et grossesse</title><year>1999</year><source><label>Gastroentérologie Clinique et Biologique</label><nom>Gastroentérologie Clinique et Biologique</nom><volume>23</volume><number>10</number></source><pertinence>97</pertinence><authors></authors><link>http://www.emc-consulte.com/article/98098</link></article><article number="17" type="revue" lang="FR"><title>La fréquence du virus respiratoire syncytial et des autres virus respiratoires dans les hospitalisations de l’enfant</title><year>2007</year><source><label>La Presse Médicale</label><nom>La Presse Médicale</nom><volume>37</volume><number>1-C1</number></source><pertinence>97</pertinence><authors>Marie-Joëlle El-Hajje, Florence Moulin, Nathalie de Suremain, Elizabeth Marc, Cécile Cosnes-Lambe, Charlotte Pons-Catalano, Mathie Lorrot, Martin Chalumeau, Flore Rozenberg, Josette Raymond, Pierre Lebon, Dominique Gendrel</authors><link>http://www.emc-consulte.com/article/134322</link></article><article number="18" type="traite" lang="fr"><title>&lt;i&gt;Arenaviridae&lt;/i&gt;</title><year>2009</year><source><label>Biologie clinique</label><nom>Biologie clinique</nom><fascicule>90-55-0015</fascicule></source><pertinence>97</pertinence><authors>M.-C. Georges-Courbot, S. Baize, D. Pannetier</authors><link>http://www.emc-consulte.com/article/204012</link></article><article number="19" type="revue" lang="FR"><title>&lt;i&gt;Mimivirus&lt;/i&gt; et l’histoire du vivant</title><year>2007</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>9</volume><number>2</number></source><pertinence>97</pertinence><authors>D. Raoult</authors><link>http://www.emc-consulte.com/article/77749</link></article><article number="20" type="revue" lang="fr"><title>Généralités sur arbovirus et arboviroses</title><year>2003</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>33</volume><number>8</number></source><pertinence>97</pertinence><authors>A. Chippaux</authors><link>http://www.emc-consulte.com/article/17075</link></article><article /></articleList></searchResult>
