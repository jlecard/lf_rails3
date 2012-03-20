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
require 'wcapi'

class WcapiSearchClass < ActionController::Base

  attr_reader :hits, :xml
  @cObject = nil
  @pkeyword = ""
  @feed_id = 0
  @search_id = 0
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("wcapi collection entered")
    @cObject = _collect
    @pkeyword = _qstring.join(" ")
    @feed_id = _collect.id
    @search_id = _last_id
    _lrecord = Array.new()
    
    begin
      #perform the search
      _lrecord = your_search(@pkeyword, _max.to_i)      
    rescue Exception => bang
      if _action_type != nil
         _lxml = ""
         logger.debug("ID: " + _last_id.to_s)
         my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
         return my_id, 0
      else
	 return nil
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
		status = LIBRARYFIND_CACHE_OK
		if _lprint != true
			status = LIBRARYFIND_CACHE_EMPTY
		end
		my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, status, infos_user)
	end
     else
	_lxml = ""
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
 

  def self.your_search(query, max) 
    logger.debug("starting worldcat search")
    client = WCAPI::Client.new :wskey => @cObject.user
   
    logger.debug("worldcat inspect: " + client.inspect)
    response = client.OpenSearch(:q=>query, :format=>'atom', :start=>'1', :count=>max.to_s, :cformat=>'mla')
    
    logger.debug("response inspect: " + response.inspect)
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
 
    #Parse your data
    _start_time = Time.now()

    #loop through your results and populate Record.
    logger.debug("Worldcat results: " + response.records.length.to_s)
    _hit_count = response.header["numberOfRecords"].to_s
    response.records.each  { |rec|
       logger.debug("record inspect: " + rec.inspect)
       logger.debug("title: " + normalize(rec[:title]))
       logger.debug("Summary: " + normalize(rec[:summary]))
       logger.debug("author: " + normalize(rec[:author].inspect))
       begin
          record = Record.new()
          #info = client.GetLocations(:type=>"oclc", :id => normalize(rec[:id]), :ip => LIBRARYFIND_SERVER_IP, :maximumLibraries => '1')
          #if (defined?(info.institutions[0]))
          #   if info.institutions[0][:institutionIdentifier].downcase == LIBRARYFIND_OCLC_SYMBOL.downcase
          #       record.holdings = '1'
          #   else
          #       record.holdings = '0'
          #   end
          #end

           
          linker_text = normalize(rec[:citation])
          if linker_text != ''
              linker_text = linker_text.slice(linker_text.index("</u>.")+5, linker_text.length - (linker_text.index("</u>.")+5)).chomp
	      if linker_text.index(":") != nil
                 record.publisher = linker_text.slice(0, linker_text.index(":")).chomp
		 linker_text = linker_text.slice(linker_text.index(":") +1, linker_text.length - (linker_text.index(":")+1)).chomp
	      else
		 record.publisher = ""
              end 

              if linker_text.index(",") != nil
                record.date = linker_text.slice(linker_text.index(",")+1, linker_text.length - (linker_text.index(",")+1)).chomp
	        record.date = record.date.gsub(".", "")
	 	record.date = normalizeDate(record.date.gsub("</p", "").chomp)
	      else
		record.date = ""
              end
          end
	    
          record.rank = _objRec.calc_rank({'title' => normalize(rec[:title]), 'atitle' => '', 'creator'=>normalize(rec[:author].join('')), 'date'=> '', 'rec' => rec[:summary], 'pos'=>1}, @pkeyword)
          record.vendor_name = @cObject.alt_name
          record.ptitle = normalize(rec[:title])
          record.title =  normalize(rec[:title])
          record.atitle =  ""
          record.issn =  ""
          record.isbn = ""
          record.abstract = normalize(rec[:summary])
          record.author = normalize(rec[:author].join('; '))
          record.link = ""
          record.id = @search_id.to_s + ";" + @feed_id.to_s + ";" + (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s)
          record.doi = ""
          record.openurl = ""
          record.direct_url = normalize(rec[:link])
          record.static_url = ""
          record.subject = ""
          record.callnum = ""
          record.vendor_url = normalize(@cObject.vendor_url)
          record.material_type = normalize(@cObject.mat_type)
          record.volume = ""
          record.issue = ""
          record.page = ""
          record.number = ""
          record.lang = ""
	  record.oclc_num = normalize(rec[:id])
          record.start = _start_time.to_f
          record.end = Time.now().to_f
          record.hits = _hit_count
	  record.raw_citation = normalize(rec[:citation])
          _record[_x] = record
          _x = _x + 1
       rescue Exception => bang
	logger.debug(bang)
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

  def self.normalizeDate(_string)
    return "" if _string == nil
    _string = _string.gsub(/[^0-9]/, "").chomp
    case _string.length
    when 8
      if _string.slice(4,2).to_i > 12: return _string.slice(0,4) end
      return _string.slice(0,4) + _string.slice(4,2) + _string.slice(6,2)
    when 6
      return _string.slice(0,4) + _string.slice(4,2) + "00"
    when 4
      return _string + "0000"
    else return ""
    end
  end


end
