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
require 'opensearch'
require 'rexml/document'

class OpensearchSearchClass < ActionController::Base
  include SearchClassHelper
  attr_reader :hits, :xml
  @pkeyword = ""
  @feed_url = ""
  @feed_id = ""
  @search_id = ""
  @feed_type = "" 
  @feed_name = ""
  @total_hits = 0
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user=nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    @records = []
    logger.debug("[OPENSEARCH] start search")
    _sTime = Time.now().to_f
    
    logger.debug("Analyze Params : _qtype:#{_qtype} _qstring:#{_qstring} _coll_list:#{_collect.id}")
    _qstring = UtilFormat.analyzeParams(_qtype,_qstring,_coll_list)
    logger.debug("Analyze Params after : _qstring:#{_qstring}")
      
    @collection = _collect
    @pkeyword = _qstring.join(" ")
    @infos_user = infos_user
    @max = _max
    @action = _action_type
    @feed_url = _collect.vendor_url
    @feed_id = _collect.id
    @search_id = _last_id
    @feed_type = _collect.mat_type
    @feed_name = _collect.alt_name
    
    #====================================
    # Setup the OpenSearch Request
    #====================================    
    
    begin
      #initialize
      logger.debug("COLLECT: " + _collect.host)
      objOpen = OpenSearch::OpenSearch.new _collect.host
      logger.debug("COLLECT2")
      if _collect.bib_attr != ""
        _tmparray = _collect.bib_attr.split(";")
        _tmparray.each() {|a|
          _tmparray2 = a.split("=")
          case _tmparray2[0] 
            when 'language'
            objOpen.language = _tmparray2[1]
            when 'output_encoding'
            objOpen.output_encoding = _tmparray2[1]
            when 'input_encoding'
            objOpen.input_encoding = _tmparray2[1]
          end 
        }
      end
      objOpen.count = _max
      objOpen.start_index = _start
      altname = objOpen.short_name
      
      #Do the search -- setting the openurl application 
      #type if present.
      #note -- we only support RSS and Atom
      
      logger.debug("Record Schema: " + _collect.record_schema) 
      _collect.record_schema = "application/rss+xml" if _collect.record_schema == "" 
      
      #perform the search
      _sRTime = Time.now().to_f
      feed = objOpen.search(_qstring.join(" "), _collect.record_schema)
      logger.debug("#STAT# [OPENSEARCH] base: #{@feed_name}[#{@feed_id}] recherche: " + sprintf( "%.2f",(Time.now().to_f - _sRTime)).to_s) if LOG_STATS
    rescue
      
    end
    
    if feed != nil || feed != ""
      begin
        if _collect.record_schema == 'application/rss+xml'
          @records = parse_rss(feed, _max.to_i)
        elsif _collect.record_schema == 'application/atom+xml'
          @records = parse_atom(feed)
        end
      rescue => e
        logger.error(e.message)
      end
    end
    
    save_in_cache
  end
  
  def strip_escaped_html(str, allow = [''])
    str = str.gsub("&#38;lt;", "<")
    str = str.gsub("&#38;gt;", ">")
    str = str.gsub("&lt;", "<")
    str = str.gsub("&gt;", ">")
    str.strip || ''
    allow_arr = allow.join('|') << '|\/'
    str = str.gsub(/<(\/|\s)*[^(#{allow_arr})][^>]*>/, ' ')
    str = str.gsub("<", "&lt;")
    str = str.gsub(">", "&gt;")
    return str
  end
  
  
  def parse_rss(xml, _max = 20) 
    _objRec = RecordSet.new()
    _title = ""
    _authors = ""
    _description = ""
    _subjects = ""
    _publisher = ""
    _link = ""
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
      end
    rescue
      return nil
    end
    
    namespaces = {'dc' => 'http://purl.org/dc/elements/1.1/', 
		  'dcterms' => 'http://purl.org/dc/terms/'}
    
    nodes = _xpath.xpath_all(doc, "//item", namespaces) 
    @total_hits = nodes.to_a.length.to_s
    logger.debug("HITS" + @total_hits)
    nodes.each { |item |
      if _x > _max 
        next
      end 
      logger.debug("item: " + item.to_s)
      _start_time = Time.now()
      logger.debug("Title here")
      _title = _xpath.xpath_get_text(_xpath.xpath_first(item, "title")) #item.elements["title"][0].value
      logger.debug("We have a title: " + _title)
      begin
        _description = strip_escaped_html(_xpath.xpath_get_text(_xpath.xpath_first(item, "description"))) if _xpath.xpath_first(item, "description") != nil
      rescue 
      end
      logger.debug("Did we process the description")
      if _xpath.xpath_first(item, "dc:subject", namespaces) != nil #item.elements["dc:subject"] != nil
        _xpath.xpath_all(item, "dc:subject", namespaces).each { |i|
          #item.elements.each("dc:subject") { |i|
          if _subjects != ""
            _subjects << "; " + _xpath.xpath_get_text(i) #i.value 
          else
            _subjects = _xpath.xpath_get_text(i) #i.value
          end
        }
      end
      logger.debug("past subjects")
      if _xpath.xpath_first(item, "dc:publisher", namespaces) != nil #item.elements["dc:publisher"] != nil 
        _publisher = _xpath.xpath_get_text(_xpath.xpath_first(item, "dc:publisher", namespaces)) #item.elements["dc:publisher"][0].value
      end
      logger.debug("past publishers")
      
      if _xpath.xpath_first(item, "dc:creator", namespaces) != nil #item.elements["dc:creator"] != nil
        _xpath.xpath_all(item, "dc:creator", namespaces).each {|i|
          #item.elements.each("dc:creator") {|i|
          if _authors != ""
            _authors << "; " + _xpath.xpath_get_text(i) #i.value
          else
            _authors = _xpath.xpath_get_text(i) #i.value
          end
        }
      end 
      logger.debug("past authors")
      _link = _xpath.xpath_get_text(_xpath.xpath_first(item, "link")) if _xpath.xpath_first(item, "link") != nil
      #if item.elements["link"] != nil: _link = item.elements["link"][0].value end
      logger.debug("past links")
      #item text
      _keyword = UtilFormat.normalize(_xpath.xpath_get_all_text(item))
      
      logger.debug("Keywords: " + _keyword) 
      record = Record.new()
      record.rank = _objRec.calc_rank({'title' => UtilFormat.normalize(_title),
                                        'atitle' => '', 
                                        'theme' => UtilFormat.normalize(_row.theme),
                                        'creator'=>UtilFormat.normalize(_authors), 
                                        'date'=>'', 
                                        'rec' => _keyword , 
                                        'pos'=>1}, 
      @pkeyword)
      logger.debug("past rank")
      record.vendor_name = @feed_name
      record.ptitle = UtilFormat.normalize(_title)
      record.title =  UtilFormat.normalize(_title)
      record.atitle =  ""
      record.issn =  ""
      record.isbn = ""
      record.abstract = UtilFormat.normalize(_description)
      record.date = ""
      record.author = UtilFormat.normalize(_authors)
      record.link = ""
      record.id = @search_id.to_s + ";" + @feed_id.to_s + ";" + (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s)
      record.doi = ""
      record.openurl = ""
      if(INFOS_USER_CONTROL and !infos_user.nil?)
        # Does user have rights to view the notice ?
        droits = ManageDroit.GetDroits(infos_user,_row.collection_id)
        if(droits.id_perm == ACCESS_ALLOWED)
          record.direct_url = UtilFormat.normalize(_link)
        else
          record.direct_url = ""
        end
      else
        record.direct_url = UtilFormat.normalize(_link)       
      end
      record.static_url = ""
      record.subject = UtilFormat.normalize(_subjects)
      record.publisher = ""
      record.callnum = ""
      @feed_url = "" if !@feed_url
      record.vendor_url = @feed_url
      record.material_type = UtilFormat.normalize(@feed_type)
      record.theme = "" # chkString(uniqString(_theme))
      record.category = ""
      record.volume = ""
      record.issue = ""
      record.page = ""
      record.number = ""
      record.lang = ""
      record.start = _start_time.to_f
      record.end = Time.now().to_f
      record.hits = @total_hits
      record.identifier = ""
      _record[_x] = record
      _x = _x + 1
    }
    return _record 
    
  end  
  
  def parse_atom(xml)
    _objRec = RecordSet.new()
    _title = ""
    _authors = ""
    _description = ""
    _subjects = ""
    _publisher = ""
    _link = ""
    _record = Array.new()
    _x = 0
    
    doc = REXML::Document.new(xml)
    @total_hits = doc.elements["//entry"].to_a().length.to_s 
    doc.elements.each("//entry") { |item |
      _start_time = Time.now()
      _title = item.elements["title"][0].value
      _description = strip_escaped_html(item.elements["summary"][0].value) if item.elements["summary"] != nil
      logger.debug("summary")
      if item.elements["category"] != nil
        item.elements.each("category") { |i|
          if _subjects != ""
            _subjects << "; " + i.attributes["term"]
          else
            _subjects = i.attributes["term"]
          end
        }
      end
      logger.debug("subjects")
      _publisher = ""
      if item.elements["author"] != nil
        item.elements.each("author") {|i|
          if _authors != ""
            _authors << "; " + i.elements["name"][0].value
          else
            _authors = i.elements["name"][0].value
          end
        }
      end
      logger.debug("authors")
      if item.elements["link"] != nil
        _link = item.elements["link"].attributes['href']
      end
      logger.debug("links")
      
      record = Record.new()
      record.rank = _objRec.calc_rank({'title' => UtilFormat.normalize(_title), 'atitle' => '', 'creator'=>UtilFormat.normalize(_authors), 'date'=>'', 'rec' => item.text, 'pos'=>1}, @pkeyword)
      record.vendor_name = @feed_name
      record.ptitle = UtilFormat.normalize(_title)
      record.title =  UtilFormat.normalize(_title)
      record.atitle =  ""
      record.issn =  ""
      record.isbn = ""
      record.abstract = UtilFormat.normalize(_description)
      record.date = ""
      record.author = UtilFormat.normalize(_authors)
      record.link = ""
      record.id = @search_id.to_s + ";" + @feed_id.to_s + ";" + (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s)
      record.doi = ""
      record.openurl = ""
      record.direct_url = UtilFormat.normalize(_link)
      record.static_url = ""
      record.subject = UtilFormat.normalize(_subjects)
      record.publisher = ""
      record.callnum = ""
      @feed_url = "" if !@feed_url
      record.vendor_url = @feed_url
      record.material_type = UtilFormat.normalize(@feed_type)
      record.volume = ""
      record.issue = ""
      record.theme = "" # chkString(uniqString(_theme))
      record.category = ""
      record.page = ""
      record.number = ""
      record.lang = ""
      record.start = _start_time.to_f
      record.end = Time.now().to_f
      record.hits = @total_hits
      record.identifier = ""
      _record[_x] = record
      _x = _x + 1
    }
    return _record
  end

  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user))
  end
end
