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
require 'keesing'

class KeesingSearchClass < ActionController::Base

  attr_reader :hits, :xml, :total_hits
  @cObject = nil
  @pkeyword = ""
  @search_id = 0
  @hits = 0
  @total_hits = 0
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _qoperator, _last_id, job_id = -1, infos_user = nil, options = nil, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("[KeesingSearchClass] [SearchCollection]")
    @cObject = _collect
    @pkeyword = _qstring.join(" ")
    @search_id = _last_id
    _lrecord = Array.new()

    begin
      #perform the search
      "[KeesingSearchClass][SearchCollection] URL: #{@cObject.url}"
      browser = KeesingBrowserClass.new(@cObject.url, logger)
      browser.search(@pkeyword, _max.to_i)
      @total_hits = browser.total
      result_list = browser.result_list
      logger.debug("[KeesingSearchClass] [SearchCollection] Search performed")
      logger.debug("[KeesingSearchClass] [SearchCollection] Number fetched #{result_list.size}")
    rescue Exception => bang
      logger.debug("[KeesingSearchClass] [SearchCollection] error: " + bang.message)
      logger.debug("[KeesingSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
      if _action_type != nil
        _lxml = ""
        logger.debug("ID: " + _last_id.to_s)
        my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY, infos_user)
        return my_id, 0, 0
      else
        return nil
      end
    end

    if !result_list.nil?
      begin
        _lrecord = parse_results(result_list, infos_user)
      rescue Exception => bang
        logger.error("[KeesingSearchClass] [SearchCollection] error: " + bang.message)
        logger.debug("[KeesingSearchClass] [SearchCollection] trace:" + bang.backtrace.join("\n"))
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
        status = LIBRARYFIND_CACHE_EMPTY if !_lprint
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

  def self.parse_results(result_list, infos_user)
    logger.debug("[KeesingSearchClass][parse_results] Entering method...")
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
    result_list.each  { |item|
      next if item.nil?
      logger.debug("[KeesingSearchClass][parse_results] looping through results...")
      begin
        _title = UtilFormat.html_decode(item['short_desc'])
        logger.debug("[KeesingSearchClass][parse_results] Title: " + _title) if _title
        _authors = ""
        _description = UtilFormat.html_decode(item['description'])
        _subjects = "#{UtilFormat.html_decode(item['short_desc'])}"
        _link = item['link']
        _keyword = UtilFormat.html_decode(normalize(_title) + " " + normalize(_description) + normalize(_subjects))
        _date = item['date']
        _source_node = @cObject.alt_name
        record = Record.new
        vendor_name = @cObject.alt_name
        record_link = @cObject.vendor_url
        record_id =  (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s) + ";" + @cObject.id.to_s + ";" + @search_id.to_s

        record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>_date, 'rec' => _keyword , 'pos'=>1}, @pkeyword)

        record.vendor_name = vendor_name
        record.ptitle = _title
        record.title =  _title
        record.atitle =  ""
        record.issn =  ""
        record.isbn = ""
        record.abstract = _description
        record.date = _date
        record.author = ""
        record.link = normalize(record_link)
        record.id =  record_id
        record.doi = ""
        record.openurl = ""
        if(INFOS_USER_CONTROL and !infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(infos_user,@cObject.id)
          if(droits.id_perm == ACCESS_ALLOWED)
            record.direct_url = _link
          else
            record.direct_url = "";
          end
        else
          record.direct_url = _link
        end
        static_url = @cObject.vendor_url
        record.static_url = static_url
        record.subject = _subjects
        pub = @cObject.alt_name
        record.publisher = pub
        record.vendor_url = normalize(static_url)
        mat_type = @cObject.mat_type
        record.material_type = mat_type
        record.volume = ""
        record.issue = ""
        record.page = ""
        record.number = ""
        record.callnum = ""
        record.lang = ""
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        record.hits = @hits
        action_allowed = @cObject.actions_allowed
        record.actions_allowed = action_allowed
        _record[_x] = record
        _x = _x + 1
      rescue Exception => bang
        logger.debug("[KeesingSearchClass][parse] parse_result error: #{bang.message}")
        logger.debug("[KeesingSearchClass][parse] parse_result trace: #{bang.backtrace.join("\n")}" )
        next
      end
    }
    return _record

  end

  def self.GetRecord(idDoc, idCollection, idSearch, infos_user = nil)
    return (CacheSearchClass.GetRecord(idDoc, idCollection, idSearch, infos_user));
  end

  def self.normalize(_string)
    return UtilFormat.normalize(_string) if _string != nil
    return ""
  end

end
