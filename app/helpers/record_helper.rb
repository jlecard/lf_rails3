# $Id: record_helper.rb 1285 2009-03-02 08:52:34Z reeset $

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

module RecordHelper

  #helper methods for creating citations
   
   def display_year(_details) 
    _year=_details.date[0,4]
  end
  
  def trim_punctuation(_string)
    _string.strip!
    if _string!=nil && _string!=""
      _length=_string.length
      if _string[_length-1,1]==';' || _string[_length-1,1]=='.' || _string[_length-1,1]==','
        _string=_string[0,_length-1]
      end
    end
    h(_string) 
  end  
  
  def append_punctuation(_string,_punctuation)
    _string.strip!
    if _string!=nil && _string!=""
      _string=trim_punctuation(_string)
      _string=_string+_punctuation
    end
    _string
  end
  
   def surround_with(_string,_punctuation1,_punctuation2)
    _string.strip!
    if _string!=nil && _string!=""
      _string=_punctuation1+_string+_punctuation2
    end
    _string
  end
  
  def author_citation(material)
    citation=""
    if material.author!=nil && material.author!=''
      citation=citation+append_punctuation(material.author,'.')+' '
    end
    citation
  end
  
  def publisher_citation(book)
    citation=""
    if book.publisher!=nil && book.publisher!=''
      citation=citation+append_punctuation(book.publisher,',')+" "
    end
    citation
  end
  
  def year_citation(book)
    citation=""
    if book.date!=nil && book.date!=''
      citation=citation+append_punctuation(display_year(book),".")
    end
    citation
  end

  def title_citation(article)
    citation=""
    if article.ptitle!=nil && article.ptitle!=''
      citation=citation+surround_with(append_punctuation(article.ptitle,'.'),'"','"')+" "
    end
    citation
  end
  
  def url_citation(image)
    citation=""
    if image.direct_url!=nil && image.direct_url!= ''
      citation=citation+append_punctuation(surround_with(h(image.direct_url),'<','>'),'.')
    end
    citation
  end
  
  def page_date_citation(article)
    citation=""
    if article.date!=nil && article.date!=''
      citation=citation+surround_with(display_year(article),'(',')')
      if article.page!=nil && article.page!= ''
        citation=append_punctuation(citation,' :')
      end
    end
    if article.page!=nil && article.page!= ''
      citation=citation+append_punctuation(article.page,'.')
    end
    citation
  end
  
  def volume_citation(article)
    citation=""
    if article.volume!=nil && article.volume!=''
      citation=citation+trim_punctuation(article.volume)
    end
    citation
  end
  
    def date_citation(_details) 
    _year=_details.date[0,4]
    _month=''
    _day=''
    if _details.date.length>4
      _month_num=_details.date[4,2]
      _month = case _month_num
      when "01" then "Jan "
      when "02" then "Feb "
      when "03" then "Mar "
      when "04" then "Apr "
      when "05" then "May "
      when "06" then "June "
      when "07" then "July "
      when "08" then "Aug "
      when "09" then "Sep "
      when "10" then "Oct "
      when "11" then "Nov "
      when "12" then "Dec "
      else           ""
      end
    end
    if _details.date.length>6 && _details.date[6,2]!="00"
      _day=_details.date[6,2]+" "
    end
      _date_string=_day+_month + _year
    end
  
  
  def build_filter_params(filter, tab_template)
    completed_param=""
    logger.debug("[build_filter_params] idTab : #{@idTab}")
    if @completed!=nil and !@completed.empty?
      completed_param=@completed*','
    end
      params={  "query[max]"    => @max,
                "query[mod]"    => @mod,
                "mode"          => @mode,
                "sets"          => @sets,
                "query[string]" => @query*',,,',
                "sort_value"    => @sort_value,
                "query[start]"  => @start,
                "tab_template"  => tab_template,
                "query[type]"   => @type*',',
                "filter"        => filter,
                "completed"     => completed_param,
                'idTab'         => @idTab
             }
    params 
  end

  def build_rss_params(filter)
      params={"filter"        => filter,
              "query[max]"    => @max,
              "query[mod]"    => @mod,
              "mode"          => @mode,
              "sets"          => @sets,
              "query[string]" => @query*',,,',
              "sort_value"    => @sort_value,
              "query[start]"  => @start,
              "tab_template"  => @tab_template,
              "query[type]"   => @type*','
             }
    params

   end
  
   def build_pagination_params(filter, page)
    completed_param=""
    if @completed!=nil and !@completed.empty?
      completed_param=@completed*','
    end
      params={"filter"        => filter,
              "query[max]"    => @max,
              "query[mod]"    => @mod,
              "mode"          => @mode,
              "sets"          => @sets,
              "query_sets"    => @sets,
              "query[string]" => @query*',,,',
              "sort_value"    => @sort_value,
              "query[start]"  => @start,
              "tab_template"  => @tab_template,
              "query[type]"   => @type*',',
              "completed"     => completed_param,
              'page'          => '%s'  % page, 
              'mobile'        => @IsMobile,
              'idTab'         => @idTab
              }
    params 
  end
  
  
    def build_pinging_params      
      params={  "query[max]"    => @max,
                "query[mod]"    => @mod,
                "mode"          => @mode,
                "sets"          => @sets,
                "query_sets"    => @sets,
                "query[string]" => @query*',,,',
                "sort_value"    => @sort_value,
                "query[start]"  => @start,
                "tab_template"  => @tab_template,
                "query[type]"   => @type*',',
                "filter"        => @filter,
                "mobile"        => @IsMobile,
                "jobs"          => @jobs*',',
                'idTab'         => @idTab,
                'query[operator]' => @operator*','}          
    params 
  end

end
