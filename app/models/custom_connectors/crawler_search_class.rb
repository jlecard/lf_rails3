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


require 'cached_search'
require 'record_set'
require 'rubygems'
require 'net/http'
require 'cgi'
require 'solr'

class CrawlerSearchClass < ApplicationController
  
  include Solr  
  include SearchClassHelper
  attr_reader :hits, :xml, :total_hits
  @collection = nil
  @pkeyword = ""
  @search_id = 0
  @hits = 0
  @total_hits = 0
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil ,options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.info("[CrawlerSearchClass][SearchCollection] params :#{_collect}, #{_qtype}, #{_qstring}, #{_start}, #{_max}, #{_qoperator}, #{_last_id}, #{job_id}, #{infos_user} ,#{options}, #{_session_id}, #{_action_type}, #{_data}, #{_bool_obj}")
    logger.info("[CrawlerSearchClass] [SearchCollection] entered")
    @collection = _collect
    @pkeyword = _qstring.join(" ")
    @search_id = _last_id
    @infos_user = infos_user
    @max = _max
    @action = _action_type
    @records = []
    logger.debug("[CrawlerSearchClass][SearchCollection] params :#{_collect}, #{_qtype}, #{_qstring}, #{_start}, #{_max}, #{_qoperator}, #{_last_id}, #{job_id}, #{infos_user} ,#{options}, #{_session_id}, #{_action_type}, #{_data}, #{_bool_obj}")
    begin
      #initialize
      logger.info("[CrawlerSearchClass] [SearchCollection] host : " + @collection.host)
      
      #perform the search
      conn = Solr::Connection.new(@collection.host)
      filter_query = @collection.definition
      logger.info("[CrawlerSearchClass] [SearchCollection] filter_query: #{filter_query}")
      raw_query_string, opt = UtilFormat.generateRequestSolr(_qtype, _qstring, _qoperator, filter_query, false, nil, nil, _max, options)
      raw_query_string = raw_query_string.gsub("keyword:","content_ml:") 
      logger.info("[CrawlerSearchClass] [SearchCollection] RAW STRING: " + raw_query_string)
    
      _response = conn.query(raw_query_string, opt)
      @total_hits = _response.total_hits
      logger.info("[CrawlerSearchClass] [SearchCollection] Search performed - found #{@total_hits}")
      
    rescue => bang
      logger.error("[CrawlerSearchClass] [SearchCollection] error: " + bang.message)
      logger.debug("[CrawlerSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
    end
    
    if _response
      begin
        logger.debug("[CrawlerSearchClass] [SearchCollection] Parsing...")
        @records = parse_crawler(_response, @collection.id, @infos_user)
      rescue => bang
        logger.error("[CrawlerSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[CrawlerSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
      end
    end
    save_in_cache
  end
  
  def parse_crawler(hits, collection_id, infos_user) 
    #logger.debug("[CrawlerSearchClass][parse] Entering method...")
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
    
    hits.each  { |hit|
      #logger.info("[CrawlerSearchClass][parse_crawler] looping through results...")
      #logger.debug("[CrawlerSearchClass][parse_crawler] #{hit.inspect}...")
      begin
        _title = hit["title_dis"]
        
        #next if !_title
        _authors = hit["author"]
        _description = hit["summary"]
        _subject = hit["subject"]
        _link = hit["id"]
        _keyword = UtilFormat.html_decode(title) + " " + _description + _subject
        _date = hit["createtime"]
        _source = hit["source_str"]
        record = Record.new()
        record.rank = _objRec.calc_rank({'title' => _title, 'atitle' => '', 'creator'=>_authors, 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
        record.vendor_name = @collection.alt_name
        record.ptitle = UtilFormat.html_decode(_title)
        record.title =  UtilFormat.html_decode(_title)
        record.atitle =  ""
        record.issn =  ""
        record.isbn = ""
        record.abstract = hit["summary"]
        record.date = _date
        record.author = _authors
        record.link = @collection.vendor_url
        record.id =  (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s) + ";" + @collection.id.to_s + ";" + @search_id.to_s
        record.doi = ""
        record.openurl = ""
        record = set_record_access_link(record, _link)
        
        record.static_url = @collection.vendor_url
        record.subject = _subject
        record.publisher = _source
        record.source = _source
        record.vendor_url = ""
        #logger.debug("[CrawlerSearchClass][parse_crawler] Record label = #{record.publisher}")
        material_type = hit["document_type"]
        logger.debug("[CrawlerSearchClass][parse_crawler] raw material_type = #{material_type}")
        if !material_type.nil?
          DocumentType.save_document_type(material_type, collection_id)
          record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(material_type),collection_id)
          logger.debug("[CrawlerSearchClass][parse_crawler] raw material_type = #{material_type}")
        else
          record.material_type = @collection.mat_type
        end
        record.format = hit["contenttyperoot"]
        record.volume = ""
        record.issue = ""
        record.page = "" 
        record.number = ""
        record.callnum = ""
        record.lang = ""
        record.hits = @total_hits
        logger.debug("[CrawlerSearchClass][parse_crawler] record: #{record}")
        logger.debug("[CrawlerSearchClass][parse_crawler] record: #{record.inspect}")
        @records.push(record)
        _x = _x + 1
      rescue Exception => bang
        logger.debug("[CrawlerSearchClass][parse_crawler] error: " + bang)
        logger.debug("[CrawlerSearchClass][parse_crawler] trace: " + bang.backtrace.join("\n"))
        next
      end
    }
    #logger.info("[CrawlerSearchClass][parse_crawler] _record returning: #{_record.size}" )
    return @records 
    
  end
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user));
  end
  
  def normalize(_string)
    return UtilFormat.normalize(_string) if _string
    return ""
    #_string = _string.gsub(/\W+$/,"")
    #return _string
  end
  
end


#<article number="2" type="revue" lang="FR"><title>Virus émergents ou menaces à répétition</title><year>2005</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>7</volume><number>2</number></source><pertinence>99</pertinence><authors>B. Lina</authors><link>http://www.emc-consulte.com/article/77669</link></article><article number="4" type="revue" lang="fr"><title>Émergences et barrières d'espèces</title><year>2004</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>34</volume><number>11</number></source><pertinence>98</pertinence><authors>A. Vabret</authors><link>http://www.emc-consulte.com/article/28153</link></article><article number="5" type="revue" lang="fr"><title>La grippe saisonnière</title><year>2010</year><source><label>Pathologie Biologie</label><nom>Pathologie Biologie</nom><volume>58</volume><number>2</number></source><pertinence>98</pertinence><authors>A. Vabret, J. Dina, D. Cuvillon-Nimal, E. Nguyen, S. Gouarin, J. Petitjean, J. Brouard, F. Freymuth</authors><link>http://www.emc-consulte.com/article/249607</link></article><article number="6" type="revue" lang="fr"><title>Virus Polyoma nouvellement découverts</title><year>2008</year><source><label>Pathologie Biologie</label><nom>Pathologie Biologie</nom><volume>57</volume><number>2</number></source><pertinence>98</pertinence><authors>H. Laude, P. Lebon</authors><link>http://www.emc-consulte.com/article/202068</link></article><article number="7" type="revue" lang="FR"><title>Le point sur l'infection par le virus West Nile</title><year>2001</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>3</volume><number>4</number></source><pertinence>98</pertinence><authors></authors><link>http://www.emc-consulte.com/article/77501</link></article><article number="8" type="revue" lang="fr"><title>Originalité des inhibiteurs d'entrée</title><year>2009</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>39</volume><number>10S1</number></source><pertinence>98</pertinence><authors>J. Izopet</authors><link>http://www.emc-consulte.com/article/228917</link></article><article number="9" type="revue" lang="fr"><title>Particularités épidémiologiques et prévention des infections nosocomiales virales</title><year>2008</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>11</volume><number>1</number></source><pertinence>97</pertinence><authors>O. Traor&amp;#x00E9;, C. Aumeran, C. Henquell</authors><link>http://www.emc-consulte.com/article/200739</link></article><article number="10" type="traite" lang="fr"><title>Virus syncytial respiratoire et virus para-influenza humains : épidémiologie</title><year>2003</year><source><label>Pédiatrie - Maladies infectieuses</label><nom>Pédiatrie - Maladies infectieuses</nom><fascicule>4-285-A-05</fascicule></source><pertinence>97</pertinence><authors>F. Freymuth</authors><link>http://www.emc-consulte.com/article/24105</link></article><article number="11" type="traite" lang="fr"><title>Virus respiratoire syncytial, métapneumovirus et virus para-influenza humains : propriétés des virus, multiplication, épidémiologie</title><year>2007</year><source><label>Pédiatrie - Maladies infectieuses</label><nom>Pédiatrie - Maladies infectieuses</nom><fascicule>4-285-A-05</fascicule></source><pertinence>97</pertinence><authors>F. Freymuth</authors><link>http://www.emc-consulte.com/article/58411</link></article><article number="12" type="revue" lang="en"><title>Amino acid and codon use: in two influenza viruses and three hosts</title><year>2007</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>37</volume><number>6</number></source><pertinence>97</pertinence><authors>C. Scapoli, S. De Lorenzi, G. Salvatorelli, I. Barrai</authors><link>http://www.emc-consulte.com/article/64394</link></article><article number="13" type="traite" lang="fr"><title>Poxvirus</title><year>2002</year><source><label>Biologie clinique</label><nom>Biologie clinique</nom><fascicule>90-55-0080</fascicule></source><pertinence>97</pertinence><authors>Antoine Garbarg Chenon, Jean-Claude Nicolas</authors><link>http://www.emc-consulte.com/article/61421</link></article><article number="14" type="revue" lang="fr"><title>Aspects urologiques de l'infection à &lt;i&gt;Polyomavirus&lt;/i&gt;</title><year>2009</year><source><label>Progrès en Urologie</label><nom>Progrès en Urologie</nom><volume>20</volume><number>1</number></source><pertinence>97</pertinence><authors>M. Thoulouzan, M. Courtade-Saidi, N. Kamar, L. Bellec, E. Huyghe, M. Souli&amp;#x00E9;, P. Plante</authors><link>http://www.emc-consulte.com/article/238858</link></article><article number="15" type="traite" lang="fr"><title>Hépatites d'étiologie inconnue</title><year>2004</year><source><label>Hépatologie</label><nom>Hépatologie</nom><fascicule>7-015-B-59</fascicule></source><pertinence>97</pertinence><authors>I. Chemin, P. Merle, R. Parana, C. Trepo</authors><link>http://www.emc-consulte.com/article/25618</link></article><article number="16" type="revue" lang="FR"><title>Virus de l'hépatite C et grossesse</title><year>1999</year><source><label>Gastroentérologie Clinique et Biologique</label><nom>Gastroentérologie Clinique et Biologique</nom><volume>23</volume><number>10</number></source><pertinence>97</pertinence><authors></authors><link>http://www.emc-consulte.com/article/98098</link></article><article number="17" type="revue" lang="FR"><title>La fréquence du virus respiratoire syncytial et des autres virus respiratoires dans les hospitalisations de l’enfant</title><year>2007</year><source><label>La Presse Médicale</label><nom>La Presse Médicale</nom><volume>37</volume><number>1-C1</number></source><pertinence>97</pertinence><authors>Marie-Joëlle El-Hajje, Florence Moulin, Nathalie de Suremain, Elizabeth Marc, Cécile Cosnes-Lambe, Charlotte Pons-Catalano, Mathie Lorrot, Martin Chalumeau, Flore Rozenberg, Josette Raymond, Pierre Lebon, Dominique Gendrel</authors><link>http://www.emc-consulte.com/article/134322</link></article><article number="18" type="traite" lang="fr"><title>&lt;i&gt;Arenaviridae&lt;/i&gt;</title><year>2009</year><source><label>Biologie clinique</label><nom>Biologie clinique</nom><fascicule>90-55-0015</fascicule></source><pertinence>97</pertinence><authors>M.-C. Georges-Courbot, S. Baize, D. Pannetier</authors><link>http://www.emc-consulte.com/article/204012</link></article><article number="19" type="revue" lang="FR"><title>&lt;i&gt;Mimivirus&lt;/i&gt; et l’histoire du vivant</title><year>2007</year><source><label>Antibiotiques</label><nom>Antibiotiques</nom><volume>9</volume><number>2</number></source><pertinence>97</pertinence><authors>D. Raoult</authors><link>http://www.emc-consulte.com/article/77749</link></article><article number="20" type="revue" lang="fr"><title>Généralités sur arbovirus et arboviroses</title><year>2003</year><source><label>Médecine et maladies infectieuses</label><nom>Médecine et maladies infectieuses</nom><volume>33</volume><number>8</number></source><pertinence>97</pertinence><authors>A. Chippaux</authors><link>http://www.emc-consulte.com/article/17075</link></article><article /></articleList></searchResult>
