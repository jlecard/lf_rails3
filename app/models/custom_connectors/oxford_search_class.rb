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
require 'oxford_browser_class'
require 'oxforddnb_browser_class'
class OxfordSearchClass < ActionController::Base
  
  attr_reader :hits, :xml, :total_hits
  include SearchClassHelper
  @collection = nil
  @pkeyword = ""
  @search_id = 0
  @hits = 0
  @total_hits = 0
  
  def SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[OxfordSearchClass] [SearchCollection]")
    @collection = _collect
    @pkeyword = _qstring.join(" ")
    @search_id = _last_id
    @records = []
    @action = _action_type
    @max = _max.to_i
    
    begin
      #perform the search
      klass = eval("#{@collection.record_schema.capitalize}BrowserClass")
      if !proxy?
        oxford_browser = klass.new(@collection.url, logger)
      else
        oxford_browser = klass.new(@collection.url, logger, @proxy_host, @proxy_port)
      end
      oxford_browser.search(@pkeyword, @max)
      @total_hits = oxford_browser.result_count
      result_list = oxford_browser.result_list
      logger.debug("[OxfordSearchClass] [SearchCollection] Search performed")
      parse_results(result_list) if result_list
      logger.debug("[OxfordSearchClass] [SearchCollection] Number fteched #{result_list.size}")
    rescue => bang
      logger.debug("[OxfordSearchClass] [SearchCollection] error: " + bang.message)
      logger.debug("[OxfordSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
    end
    save_in_cache
  end
  
  def parse_results(result_list) 
    logger.debug("[OxfordSearchClass][parse_results] Entering method...")
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
    _start_time = Time.now()
    
    @hits = result_list.size
    result_list.each  do |item|
      next if item.nil?
      logger.debug("[OxfordSearchClass][parse_results] looping through results...")
      begin
        _title = UtilFormat.html_decode(item['short_desc']) 
        logger.debug("[OxfordSearchClass][parse_results] Title: " + _title) if _title
        _authors = ""
        _description = UtilFormat.html_decode(item['description'])
        _subjects = "#{UtilFormat.html_decode(item['text'])}"
        _link = item['link']
        _keyword = UtilFormat.html_decode(normalize(_title) + " " + normalize(_description) + normalize(_subjects))
        _date = ""
        _source_node = @collection.alt_name
        record = Record.new()
        
        
        record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
        
        record.vendor_name = @collection.alt_name
        record.ptitle = _title
        record.title =  UtilFormat.html_decode(item['text']) 
        record.atitle =  ""
        record.issn =  ""
        record.isbn = ""
        record.abstract = _description
        record.date = ""
        record.author = ""
        record.link = normalize(@collection.vendor_url)
        record.id =  (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s) + ";" + @cObject.id.to_s + ";" + @search_id.to_s
        record.doi = ""
        record.openurl = ""
        if(INFOS_USER_CONTROL and !@infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(@infos_user,@collection.id)
          if droits.id_perm == ACCESS_ALLOWED
            record.direct_url = _link
          else
            record.direct_url = ""
          end
        else
          record.direct_url = _link          
        end
        
        record.static_url = @collection.vendor_url
        record.subject = _subjects
        record.publisher = @collection.alt_name
        record.vendor_url = normalize(@collection.vendor_url)
        record.material_type = @collection.mat_type
        record.volume = ""
        record.issue = ""
        record.page = "" 
        record.number = ""
        record.callnum = ""
        record.lang = ""
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.hits = @hits
        record.actions_allowed = @collection.actions_allowed
        _record[_x] = record
        _x = _x + 1
      rescue => bang
        logger.error("[OxfordSearchClass][parse] parse_result error: " + bang)
        logger.debug("[OxfordSearchClass][parse] parse_result trace: " + bang.backtrace.join("\n"))
        next
      end
    end
    @records = _record
    @records
  end
  
  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user));
  end

  
end
