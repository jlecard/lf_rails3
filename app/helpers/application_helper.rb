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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def select_box_items
    if !params[:idTab].blank? and @idTab != params[:idTab]
      @idTab = params[:idTab]
      @filter_tab = SearchTabFilter.load_filter(@idTab)
      @groups_tab = SearchTab.load_groups(@idTab)
    else
      reload = @idTab.blank?
      if reload
        @idTab = "1"
        @filter_tab = SearchTabFilter.load_filter(@idTab)
        @groups_tab = SearchTab.load_groups(@idTab)
      else
        @filter_tab ||= SearchTabFilter.load_filter(@idTab)
        @groups_tab ||= SearchTab.load_groups(@idTab)
      end
    end
    @linkMenu ||= SearchTab.load_menu
  end

  def short_abstract(_details)
    _abstract_length = 230
    h(_details.abstract[0,_abstract_length-1])
  end

  def display_icon(_details)
    if _details!=nil and _details.material_type!=nil
      if _details.material_type.downcase=='book'
        image_tag("/images/book.gif", :border => "0", :size => "30x30", :alt=>"Book", :title=>"Book")
      elsif _details.material_type.downcase=='article'
        image_tag("/images/article.gif", :border => "0", :size => "30x30", :alt=>"Article", :title=>"Article")
      elsif _details.material_type.downcase=='newspaper'
        image_tag("/images/newspaper.gif", :border => "0", :size => "30x30", :alt=>"Newspaper", :title=>"Newspaper")
      else
      _details.material_type
      end
    end
  end

  def display_citation(_details)
    _citation = "<span style='color: #ce5500; font-style: italic'>"
    _citation = _citation + h(_details.ptitle) + "</span>"
    if _details.volume!=nil and _details.volume!=''
      _citation = _citation + "<span style='color: #ce5500'><text>, </text>"
      _citation = _citation + h(_details.volume)
      if _details.issue != nil and _details.issue != ''
        _citation = _citation + "<text>(</text>"
        _citation = _citation + h(_details.issue) + "<text>)</text>"
      end
      if _details.page!=nil and _details.page!=''
        _citation = _citation + "<text>, </text>" + _details.page
      end
      _citation=_citation+"</span>"
    else
      _citation = _citation + "<span style='color: #ce5500'>"
      if _details.page!=''
        _citation = _citation + "<text>, p.</text>" + _details.page
      end
      _citation=_citation+"</span>"
    end
    _citation
  end

  def display_source(_details)

    if _details.publisher!=''
    _from=_details.publisher
    else
      if _details.title!=''
      _from=_details.title
      else
      _from=_details.vendor_name
      end
    end

    if _from!=nil && _from!=""
      _from.strip!
      _length=_from.length
      if _from[_length-1,1]==';' || _from[_length-1,1]==','
      _from=_from[0,_length-1]
      end
    end
    h(_from)

  end

  def format_date_range(record)
    date_string=record.date.to_s
    if record.material_type.downcase!="finding aid"
      date_string=format_date(record)
    else
      if record.date.length==8
        date_string=record.date[0,4]+"-"+record.date[4,4]
      end
    end
    date_string
  end

  def format_date(record)
    if record.material_type.downcase=="finding aid"
      format_date_range(record)
    else
      date=record.date
      _year=date[0,4]
      _month=''
      _day=''
      if date.length>4
        _month_num=date[4,2]
        _month = case _month_num
        when "01" then "JAN"
        when "02" then "FEB"
        when "03" then "MAR"
        when "04" then "APR"
        when "05" then "MAY"
        when "06" then "JUN"
        when "07" then "JUL"
        when "08" then "AUG"
        when "09" then "SEP"
        when "10" then "OCT"
        when "11" then "NOV"
        when "12" then "DEC"
        else           ""
        end
      end
      if date.length>6 && date[6,2]!="00"
      _day=date[6,2]
      end
      _date_string=''
      if date!="00000000"
        _date_string=_date_string+_month
        if _day!=''
          _date_string=_date_string + ' ' + _day
        end
        if _month!='' or _day!=''
          _date_string=_date_string + ', '
        end
      _date_string=_date_string + _year
      end
    _date_string
    end
  end

  def display_date(_details)
    if _details.material_type.downcase=="finding aid"
      _date_string="<span id='date'>"+format_date_range(_details)+"</span>"
    else
      _date_string=''
      _id='date'
      if _details.date!="00000000"
        _current_date_string=build_current_date_string
        if _current_date_string < _details.date
          _id="date-future"
          _date_string="Arriving: "
        end
        _date_string="<span id="+_id+">"+_date_string+format_date(_details)+"</span>"
      end
    end
    _date_string
  end

  def build_current_date_string
    # Should return YYYYMMDD
    Time.now.iso8601[0..9].gsub '-', ''
  end

  def lf_paginate
    if @results==nil or @results.empty?
    return
    end
    _num_links=15
    _added_links=7
    @results_count=@results.length
    # @page => "Which page we're showing"
    if params[:page]
      @page = params[:page].to_i
    else
    @page = 1
    end

    @show_previous = false
    @show_next = false
    @page_list = []

    # Check for obvious errors
    #for this case, we add @page_size to the result count to handle the case of the last page
    if @results_count + @page_size <= (@page * @page_size)
    return
    elsif @page <= 0
    return
    end

    # Limit the result set to this page
    @start_item = (@page - 1) * @page_size
    @finish_item = (@page * @page_size)
    if @finish_item > @results_count
    @finish_item = @results_count
    end
    @results_page = @results[@start_item...@finish_item]

    # Should we show the "Previous" link?
    if @page != 1
    @show_previous = true
    @previous = @page - 1
    end

    # Should we show the "Next" link?
    _num_pages = (@results_count / Float(@page_size)).ceil
    if @page < _num_pages
    @show_next = true
    @next = @page + 1
    end
    # Find the page num range to display
    _first_page=@page-_added_links
    if _first_page<1 or _num_pages <= _num_links
    _first_page=1
    end
    _last_page=_first_page+_num_links
    if _last_page>_num_pages
    _last_page=_num_pages+1
    end
    @page_list = _first_page ... _num_pages+1

  end

  def escape_quote(_string)
    _new_string=_string.to_s.gsub('"') {"&quot;"}
    _new_string=_new_string.to_s.gsub("'") {"&apos;"}
    _new_string
  end

  def get_total_hits
    hits=0
    if @all_databases!=nil and !@all_databases.empty?
      @all_databases.each{|d|
        hits += d[:total_hits].to_i
      }
    end
    hits
  end

  def build_unfilter_string(key)
    filter=Array.new(@filter)
    filter.delete_if {|filter_pair|
      filter_pair.include?(key)
    }
    filter_string=build_string_from_filter(filter)
    filter_string
  end

  def build_filter_string(key, value)
    new_filter=[key,value]
    filter=Array.new(@filter)
    if !filter.include?(new_filter)
    filter<<new_filter
    end
    filter_string=build_string_from_filter(filter)
    filter_string
  end

  def build_string_from_filter(filter)
    filter_array=Array.new
    for i in 0..filter.length
      if filter[i]!=nil && !filter[i].empty?
        filter_array[i]=filter[i].join(FILTER_SEPARATOR)
      end
    end
    filter_string = filter_array.join("/")
    filter_string
  end

  def top_images
    image_results=Array.new(@all_results)
    image_results.delete_if {|_record| _record.material_type==nil or _record.material_type.downcase!="image"}
    image_results
  end

  def get_controller_path(caller)
    return controller.controller_path.to_s
  rescue
    if caller!=nil
      base_path=caller.base_path.to_s
      base_index=base_path.rindex('/')
      if base_index==nil or base_path==""
        base="application"
      else
      base=base_path[base_index+1,base_path.length]
      end
    return base.to_s
    else
    return self.controller_path.to_s
    end
    end

  def strip_quotes(_record)
    _record.vendor_name.gsub!("'") {""}
    _record.subject.gsub!("'") {""}
    _record.author.gsub!("'") {""}
    _record.date.gsub!("'") {""}
    _record.lang = "" if _record.lang == nil
    _record.lang.gsub!("'") {""}
  end

end
