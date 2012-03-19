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

class YahooSearchClass < ActionController::Base

  attr_reader :hits, :xml
  @cObject = nil
  @pkeyword = ""
  @feed_id = 0
  @search_id = 0
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("yahoo collection entered")
    @cObject = _collect
    @pkeyword = _qstring.join(" ")
    @feed_id = _collect.id
    @search_id = _last_id
    _lrecord = Array.new()
    
    begin
      #initialize
      logger.debug("COLLECT: " + _collect.host)
   
      #Do the search -- setting the openurl application 
      #type if present.
      #note -- we only support RSS and Atom
  
      #perform the search
      results = yahoo_search(@pkeyword, _max.to_i)      
      logger.debug("Search performed")
      logger.debug("Yahoo XML: " + results)
    rescue Exception => bang
      logger.debug("yahoo error " + bang)
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
	 logger.debug("Parsing yahoo")
         _lrecord = parse_yahoo(results)
      rescue Exception => bang
	logger.debug("yahoo error: " + bang)
	if _action_type != nil
	   _lxml = ""
           logger.debug("ID: " + _last_id.to_s)
           my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
           return my_id, 0
        else
	   return nil
	end
      end
    end

    _lprint = false
    if _lrecord != nil
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
		my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, status, infos_user)
	end
     else
	logger.debug("save bad metadata")
	_lxml = ""
	logger.debug("ID: " + _last_id.to_s)
	my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
     end

     if _action_type != nil
	if _lrecord != nil
	  return my_id, _lrecord.length
        else
	  return my_id, 0
        end
     else
        return _lrecord
     end
  end

  def self.yahoo_search(query, max)
    if !defined?(YAHOO_APPLICATION_ID)
       return nil
    end 
    logger.debug("Entered Yahoo Search")
    url = "http://search.yahooapis.com/WebSearchService/V1/webSearch?appid=#{YAHOO_APPLICATION_ID}&query=#{URI.encode(query)}&results=#{max.to_s}"
    logger.debug("Yahoo URL: " + url)
    begin
       xml_result_set = Net::HTTP.get_response(URI.parse(url))
       return xml_result_set.body
    rescue Exception => e
       logger.debug("yahoo search error: " + e)
       return nil
    end
  end
 
  def self.strip_escaped_html(str, allow = [''])
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
 

  def self.parse_yahoo(xml) 
    logger.debug("Entering Yahoo Parsing")
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

    xml = xml.gsub('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:yahoo:srch" xsi:schemaLocation="urn:yahoo:srch http://api.search.yahoo.com/WebSearchService/V1/WebSearchResponse.xsd" ', "")
    logger.debug("Parsed Yahoo XML: " + xml)

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
    node = _xpath.xpath_first(doc, "/ResultSet")
    logger.debug("Node: " + node.to_s)
    _hit_count = _xpath.get_attribute(node, "totalResultsAvailable")
    logger.debug("hits: " + _hit_count.to_s)

    nodes = _xpath.xpath_all(doc, "/ResultSet/Result")
    logger.debug("Nodes: " + nodes.to_s)
    logger.debug("Nodes length: " + nodes.length.to_s)

    nodes.each  { |item|
       logger.debug("yahoo looping")

       begin
          _title = _xpath.xpath_get_text(_xpath.xpath_first(item, "Title"))
          logger.debug("Title: " + _title)
          _authors = ""
          _description = _xpath.xpath_get_text(_xpath.xpath_first(item, "Summary"))
          _subjects = ""
          _link = _xpath.xpath_get_text(_xpath.xpath_first(item, "Url"))
          _keyword = normalize(_title) + " " + normalize(_description) + normalize(_subjects)
          _date = _xpath.xpath_get_text(_xpath.xpath_first(item, "ModificationDate"))
          record = Record.new()
          record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
          logger.debug("past rank")
          record.vendor_name = @cObject.alt_name
          record.ptitle = normalize(_title)
          record.title =  normalize(_title)
          record.atitle =  ""
          record.issn =  ""
          record.isbn = ""
          record.abstract = normalize(_description)
          record.date = ""
          record.author = normalize(_authors)
          record.link = ""
          record.id = @search_id.to_s + ";" + @feed_id.to_s + ";" + (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s)
          record.doi = ""
          record.openurl = ""
          record.direct_url = normalize(_link)
          record.static_url = ""
          record.subject = normalize(_subjects)
          record.publisher = ""
          record.callnum = ""
          record.vendor_url = normalize(@cObject.vendor_url)
          record.material_type = normalize(@cObject.mat_type)
          record.volume = ""
          record.issue = ""
          record.page = ""
          record.number = ""
          record.lang = ""
          record.start = _start_time.to_f
          record.end = Time.now().to_f
          record.hits = _hit_count
          _record[_x] = record
          _x = _x + 1
       rescue Exception => bang
	logger.debug("yahoo error: " + bang)
	next
       end
    }
    return _record 

  end  

  def self.normalize(_string)
    return _string.gsub(/\W+$/,"") if _string != nil
    return ""
    #_string = _string.gsub(/\W+$/,"")
    #return _string
  end

end
