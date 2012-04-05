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


class EmconsulteSearchClass < ActionController::Base
  include SearchClassHelper
  
  # <?xml version="1.0" encoding="UTF-8"?>
  # <searchResult>
  #   <articleList size="20" totalSize="20">
  #   <article number="1" type="revue" lang="FR">
  #     <title>Spécificité d'hôte des virus et passages inter-espèces</title>
  #     <year>2010</year>
  #     <source>
  #       <label>RFL - Revue francophone des laboratoires</label>
  #       <nom>RFL - Revue francophone des laboratoires</nom>
  #       <volume>40</volume>
  #       <number>423</number>
  #     </source>
  #     <pertinence>99</pertinence>
  #     <authors>Michel Segondy</authors>
  #     <link>http://www.emc-consulte.com/article/257061</link>
  #   </article>
  
  
  
  attr_reader :hits, :xml, :total_hits
  @collection = nil
  @pkeyword = ""
  @search_id = 0
  @hits = 0
  @total_hits = 0
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil ,options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("em_consultecollection entered")
    @collection = _collect
    @pkeyword = _qstring.join(" ")
    @search_id = _last_id
    @infos_user = infos_user
    @max = _max
    @action = _action_type
    
    begin
      #initialize
      logger.debug("COLLECT: " + @collection.host)
      
      #perform the search
      results = em_consult_search(@pkeyword, _max.to_i)      
      logger.debug("Search performed")
    rescue => bang
      logger.error("[EmConsulteSearchClass] [SearchCollection] error: " + bang.message)
      logger.debug("[EmConsulteSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
    end
    
    if results
      begin
        logger.debug("Parsing em_consulte")
        @records = parse_em_consulte(results, _collect.id, infos_user)
      rescue Exception => bang
        logger.error("[EmConsulteSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[EmConsulteSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
      end
    end
    save_in_cache
  end
  
  def em_consult_search(query, max)
    
    logger.debug("Entered EmConsulteSearchClass")
    query = CGI::escape(query)
    url = "http://www.em-consulte.com/externalSearch?keywords=#{query}&startresult=1&endresult=#{max}&maxdocs=#{max}"
    logger.debug("[EmConsulteSearchClass] [em_consult_search] URL: " + url)
    begin
      if proxy?
        xml_result_set = Net::HTTP.Proxy(@proxy_host,@proxy_port).get_response(URI.parse(url))
      else
        xml_result_set = Net::HTTP.get_response(URI.parse(url))
      end
      return xml_result_set.body
    rescue => e
      logger.error("[EmConsulteSearchClass] error: " + e.message)
      logger.error("[EmConsulteSearchClass] error: " + e.backtrace.join("\n"))
      return nil
    end
  end
  
  def parse_em_consulte(xml, collection_id, infos_user) 
    logger.debug("[EmConsulte Search][parse_em_consulte] Entering method...")
    _objRec = RecordSet.new()
    _title = ""
    _authors = ""
    _description = ""
    _subjects = ""
    _publisher = ""
    _link = ""
    _thumbnail = ""
    _record = Array.new()
    _x = 0
    
    _xpath = Xpath.new()
    parser = ::PARSER_TYPE
    begin
      case parser
        when 'libxml'
        _parser = LibXML::XML::Parser.new()
        _parser.string = xml
        doc = LibXML::XML::Document.new()
        doc = _parser.parse
        when 'rexml'
        doc = REXML::Document.new(xml)
        when 'nokogiri'
        doc = Nokogiri::XML.parse(xml)
      end
    rescue
      return nil
    end
    
    
    _start_time = Time.now()
    node = _xpath.xpath_first(doc, "/searchResult/articleList")
    _hit_count = _xpath.get_attribute(node, "totalSize").value
    @total_hits = _hit_count.to_s.to_i
    @hits = _xpath.get_attribute(node, "size").value
    nodes = _xpath.xpath_all(doc, "/searchResult/articleList/article")
    
    nodes.each  { |item|
      logger.debug("[EmConsulte Search][parse_em_consulte] looping through nodes...")
      begin
        _title = UtilFormat.html_decode(_xpath.xpath_get_text(_xpath.xpath_first(item, "title")))
        logger.debug("Title: " + _title) if _title
        next if !_title
        _authors = UtilFormat.html_decode(normalize(_xpath.xpath_get_text(_xpath.xpath_first(item, "authors"))))
        _description = ""
        _subjects = ""
        _link = _xpath.xpath_get_text(_xpath.xpath_first(item, "link"))
        _keyword = UtilFormat.html_decode(normalize(_title) + " " + normalize(_description) + normalize(_subjects))
        _date = _xpath.xpath_get_text(_xpath.xpath_first(item, "year"))
        _source_node = _xpath.xpath_first(item, "source")
        record = Record.new()
        record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
        logger.debug("past rank")
        record.vendor_name = @collection.alt_name
        record.ptitle = UtilFormat.html_decode(normalize(_title))
        record.title =  UtilFormat.html_decode(normalize(_title))
        record.atitle =  
        record.issn =  ""
        record.isbn = ""
        record.abstract = UtilFormat.html_decode(normalize(_title))
        record.date = normalize(_date)
        record.author = normalize(_authors)
        record.link = normalize(@collection.vendor_url)
        record.id =  (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s) + ";" + @cObject.id.to_s + ";" + @search_id.to_s
        record.doi = ""
        record.openurl = ""
        if(INFOS_USER_CONTROL and !infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(infos_user,@collection.id)
          if(droits.id_perm == ACCESS_ALLOWED)
            record.direct_url = normalize(_link).gsub("emc-consulte","em-premium") # data returned by search is buggy...
          else
            record.direct_url = "";
          end
        else
          record.direct_url = normalize(_link).gsub("emc-consulte","em-premium") # data returned by search is buggy...
        end
        
        record.static_url = @collection.vendor_url
        record.subject = normalize(_xpath.xpath_get_text(_xpath.xpath_first(_source_node, "label")))
        record.publisher = normalize(_xpath.xpath_get_text(_xpath.xpath_first(_source_node, "label")))
        record.source = record.publisher
        logger.debug("[EmSearchClass] [ParseXml] Record label = #{record.publisher}")
        record.vendor_url = normalize(@collection.vendor_url)
        material_type = _xpath.get_attribute(item, "type").value.capitalize unless _xpath.get_attribute(item, "type").nil?
        logger.debug("[ClassiquesGarnierSearchClass][parse_em_consulte] raw material_type = #{material_type}")
        if !material_type.nil?
          DocumentType.save_document_type(material_type, collection_id)
          record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(material_type),collection_id)
          logger.debug("[ClassiquesGarnierSearchClass][parse_em_consulte] raw material_type = #{material_type}")
        else
          record.material_type = @collection.mat_type
        end
        record.volume = normalize(_xpath.xpath_get_text(_xpath.xpath_first(_source_node, "volume")))
        record.issue = ""
        record.page = normalize(_xpath.xpath_get_text(_xpath.xpath_first(_source_node, "pageStart"))) + " - " + normalize(_xpath.xpath_get_text(_xpath.xpath_first(_source_node, "pageEnd"))) 
        record.number = normalize(_xpath.xpath_get_text(_xpath.xpath_first(_source_node, "number")))
        record.callnum = normalize(_xpath.xpath_get_text(_xpath.xpath_first(_source_node, "fascicule"))) if record.material_type == "Traite"
        record.lang = _xpath.get_attribute(item, "lang").value unless _xpath.get_attribute(item, "lang").nil?
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.hits = @hits
        _record[_x] = record
        _x = _x + 1
      rescue => bang
        logger.debug("[EmConsulteSearchClass][parse]em_consulte error: " + bang)
        logger.debug("[EmConsulteSearchClass][parse]em_consulte trace: " + bang.backtrace.join("\n"))
        next
      end
    }
    return _record 
    
  end
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user))
  end
  
  def normalize(_string)
    return UtilFormat.normalize(_string) if _string != nil
    return ""
    #_string = _string.gsub(/\W+$/,"")
    #return _string
  end
  
end


#<article number="2" type="revue" lang="FR"><title>Virus émergents ou menaces à répétition</title><year>2005</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>7</volume><number>2</number></source><pertinence>99</pertinence><authors>B. Lina</authors><link>http://www.emc-consulte.com/article/77669</link></article><article number="4" type="revue" lang="fr"><title>Émergences et barrières d'espèces</title><year>2004</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>34</volume><number>11</number></source><pertinence>98</pertinence><authors>A. Vabret</authors><link>http://www.emc-consulte.com/article/28153</link></article><article number="5" type="revue" lang="fr"><title>La grippe saisonnière</title><year>2010</year><source><label>Pathologie Biologie</label><nom>Pathologie Biologie</nom><volume>58</volume><number>2</number></source><pertinence>98</pertinence><authors>A. Vabret, J. Dina, D. Cuvillon-Nimal, E. Nguyen, S. Gouarin, J. Petitjean, J. Brouard, F. Freymuth</authors><link>http://www.emc-consulte.com/article/249607</link></article><article number="6" type="revue" lang="fr"><title>Virus Polyoma nouvellement découverts</title><year>2008</year><source><label>Pathologie Biologie</label><nom>Pathologie Biologie</nom><volume>57</volume><number>2</number></source><pertinence>98</pertinence><authors>H. Laude, P. Lebon</authors><link>http://www.emc-consulte.com/article/202068</link></article><article number="7" type="revue" lang="FR"><title>Le point sur l'infection par le virus West Nile</title><year>2001</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>3</volume><number>4</number></source><pertinence>98</pertinence><authors></authors><link>http://www.emc-consulte.com/article/77501</link></article><article number="8" type="revue" lang="fr"><title>Originalité des inhibiteurs d'entrée</title><year>2009</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>39</volume><number>10S1</number></source><pertinence>98</pertinence><authors>J. Izopet</authors><link>http://www.emc-consulte.com/article/228917</link></article><article number="9" type="revue" lang="fr"><title>Particularités épidémiologiques et prévention des infections nosocomiales virales</title><year>2008</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>11</volume><number>1</number></source><pertinence>97</pertinence><authors>O. Traor&amp;#x00E9;, C. Aumeran, C. Henquell</authors><link>http://www.emc-consulte.com/article/200739</link></article><article number="10" type="traite" lang="fr"><title>Virus syncytial respiratoire et virus para-influenza humains : épidémiologie</title><year>2003</year><source><label>Pédiatrie - Maladies infectieuses</label><nom>Pédiatrie - Maladies infectieuses</nom><fascicule>4-285-A-05</fascicule></source><pertinence>97</pertinence><authors>F. Freymuth</authors><link>http://www.emc-consulte.com/article/24105</link></article><article number="11" type="traite" lang="fr"><title>Virus respiratoire syncytial, métapneumovirus et virus para-influenza humains : propriétés des virus, multiplication, épidémiologie</title><year>2007</year><source><label>Pédiatrie - Maladies infectieuses</label><nom>Pédiatrie - Maladies infectieuses</nom><fascicule>4-285-A-05</fascicule></source><pertinence>97</pertinence><authors>F. Freymuth</authors><link>http://www.emc-consulte.com/article/58411</link></article><article number="12" type="revue" lang="en"><title>Amino acid and codon use: in two influenza viruses and three hosts</title><year>2007</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>37</volume><number>6</number></source><pertinence>97</pertinence><authors>C. Scapoli, S. De Lorenzi, G. Salvatorelli, I. Barrai</authors><link>http://www.emc-consulte.com/article/64394</link></article><article number="13" type="traite" lang="fr"><title>Poxvirus</title><year>2002</year><source><label>Biologie clinique</label><nom>Biologie clinique</nom><fascicule>90-55-0080</fascicule></source><pertinence>97</pertinence><authors>Antoine Garbarg Chenon, Jean-Claude Nicolas</authors><link>http://www.emc-consulte.com/article/61421</link></article><article number="14" type="revue" lang="fr"><title>Aspects urologiques de l'infection à &lt;i&gt;Polyomavirus&lt;/i&gt;</title><year>2009</year><source><label>Progrès en Urologie</label><nom>Progrès en Urologie</nom><volume>20</volume><number>1</number></source><pertinence>97</pertinence><authors>M. Thoulouzan, M. Courtade-Saidi, N. Kamar, L. Bellec, E. Huyghe, M. Souli&amp;#x00E9;, P. Plante</authors><link>http://www.emc-consulte.com/article/238858</link></article><article number="15" type="traite" lang="fr"><title>Hépatites d'étiologie inconnue</title><year>2004</year><source><label>Hépatologie</label><nom>Hépatologie</nom><fascicule>7-015-B-59</fascicule></source><pertinence>97</pertinence><authors>I. Chemin, P. Merle, R. Parana, C. Trepo</authors><link>http://www.emc-consulte.com/article/25618</link></article><article number="16" type="revue" lang="FR"><title>Virus de l'hépatite C et grossesse</title><year>1999</year><source><label>Gastroentérologie Clinique et Biologique</label><nom>Gastroentérologie Clinique et Biologique</nom><volume>23</volume><number>10</number></source><pertinence>97</pertinence><authors></authors><link>http://www.emc-consulte.com/article/98098</link></article><article number="17" type="revue" lang="FR"><title>La fréquence du virus respiratoire syncytial et des autres virus respiratoires dans les hospitalisations de l’enfant</title><year>2007</year><source><label>La Presse Médicale</label><nom>La Presse Médicale</nom><volume>37</volume><number>1-C1</number></source><pertinence>97</pertinence><authors>Marie-Joëlle El-Hajje, Florence Moulin, Nathalie de Suremain, Elizabeth Marc, Cécile Cosnes-Lambe, Charlotte Pons-Catalano, Mathie Lorrot, Martin Chalumeau, Flore Rozenberg, Josette Raymond, Pierre Lebon, Dominique Gendrel</authors><link>http://www.emc-consulte.com/article/134322</link></article><article number="18" type="traite" lang="fr"><title>&lt;i&gt;Arenaviridae&lt;/i&gt;</title><year>2009</year><source><label>Biologie clinique</label><nom>Biologie clinique</nom><fascicule>90-55-0015</fascicule></source><pertinence>97</pertinence><authors>M.-C. Georges-Courbot, S. Baize, D. Pannetier</authors><link>http://www.emc-consulte.com/article/204012</link></article><article number="19" type="revue" lang="FR"><title>&lt;i&gt;Mimivirus&lt;/i&gt; et l’histoire du vivant</title><year>2007</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>9</volume><number>2</number></source><pertinence>97</pertinence><authors>D. Raoult</authors><link>http://www.emc-consulte.com/article/77749</link></article><article number="20" type="revue" lang="fr"><title>Généralités sur arbovirus et arboviroses</title><year>2003</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>33</volume><number>8</number></source><pertinence>97</pertinence><authors>A. Chippaux</authors><link>http://www.emc-consulte.com/article/17075</link></article><article /></articleList></searchResult>
