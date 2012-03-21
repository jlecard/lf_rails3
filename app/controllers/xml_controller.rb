# $Id: record_controller.rb 1100 2007-09-26 18:45:39Z herlockt $

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

class XmlController < ApplicationController
  

def retrieve
   init_search  
   find_search_results
end 


def find_search_results(_type=@type, _query=@query, _sets=@sets, _start=@start, _max=@max)  
  begin
    logger.debug("searching for type="+_type.to_s+" query="+_query.to_s+" sets="+_sets.to_s+" start="+_start.to_s+" max="+_max.to_s)
    @results = ping_for_results(_sets, _type, _query, _start, _max) 
  rescue Exception => e
    logger.info("RecordController caught ERROR: " + e.to_s)
    logger.info(e.backtrace.to_s)
    flash.now[:error]='The following error occurred while searching: "'+e.to_s+'".<br/>Click the link labeled "Report a Problem" to send an email with a description of the error.'
  end
end

def ping_for_results(_sets=@sets, _type=@type, _query=@query, _start=@start, _max=@max)  

    ids = $objDispatch.search_async(_sets, _type, _query, _start, _max) 
    done=0
    completed=[]
    errors=[]
    job_length=ids.length
    while done==0
      count=0
      for id in ids
        item=$objDispatch.check_job_status(id)
        count=count+1
        if item.status==1
          done=0
          break
        elsif item.status==0
          ids.delete(id)
          completed<<id
        elsif item.status==-1
          errors<<id
        end
        if job_length==completed.length+errors.length
          done=1
        end
      end
    end
    return $objDispatch.get_jobs_records(completed, _max)
end

#Initialize all global variables.
#For sets, if they are specified as parameters, use those sets.  
#In the case that the group is being changed, then default to the sets for that group.
def init_search
  defaults
  init_query_and_type(params[:query][:string],params[:query][:type])
  if (params[:query][:mod] != "0") 
    initAttributeSearch(params[:query][:mod])
  end
  if params[:filter]!=nil && params[:filter]!="" && !params[:filter].empty?
    @filter=[]
    for filter_pair in params[:filter].split("/")
      if filter_pair!=nil and filter_pair!=""
        @filter<<filter_pair.split(":")
      end
    end
  end  
  if params[:query][:max]!=nil and params[:query][:max]!='' 
    @max = params[:query][:max]
  end  
  if params[:query][:mod]!=nil and params[:query][:mod]!='' 
    @mod = params[:query][:mod]
  end 
  if params[:mode]!=nil and params[:mode]!='' 
    @mode = params[:mode]
  end 
  if params[:sort_value]!=nil && params[:sort_value]!=''
    @sort_value=params[:sort_value]
  end
  if params[:query][:start]!=nil and params[:query][:start]!='' 
    @start = params[:query][:start]
  end
  if params[:tab_template]!=nil and params[:tab_template]!='' 
    @tab_template = params[:tab_template]
  end
  if params[:sets]!=nil && params[:sets]!=''
    @sets=params[:sets]
  else
    init_sets
  end
  if @sets.rindex(',')==@sets.length-1
    @sets=@sets.chop
  end
end

def defaults
  @filter=[]
  @max= max_search_results
  @mod="0"
  @mode="simple"
  @query=[""]
  @sort_value='relevance'
  @start="0"
  @type="keyword"
  @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
  @tab_template=@config["GENERAL_TEMPLATE"]
end

def buildQueryArray(query)
  queryArray=[]
  if query!=nil
    attributeArray=Array["su:", "subject:", "au:", "author:", "ti:", "title:"]
    queryArray = query.split(":")
    if queryArray[0].downcase+":"==attributeArray[0]
      queryArray[0]="subject"
    else 
      if queryArray[0].downcase+":"==attributeArray[2] 
        queryArray[0]="creator"
      else 
        if queryArray[0].downcase+":"==attributeArray[3]
          queryArray[0]="creator"
        else 
          if queryArray[0].downcase+":"==attributeArray[4]
            queryArray[0]="title"
          end
        end
      end
    end
    if queryArray.length>2 
      for _query in queryArray
        queryArray[1] = queryArray[1] + " " + _query.to_s 
      end
    end
  end
  queryArray
end

def strip_quotes(_record)
  _record.vendor_name.gsub!("'") {""}
  _record.subject.gsub!("'") {""}
  _record.author.gsub!("'") {""}
end
 
  
def init_query_and_type(query, type)
   _query_array=buildQueryArray(query) 
   if _query_array.length<2
    _type_param=type
    _query_param=query
  else
    _type_param=_query_array[0]
    _query_param=_query_array[1]
  end
  if _type_param==nil or _type_param.empty? 
    @type = ["keyword"]
  else
    @type = [_type_param]
  end
  @query = [_query_param] 
end

  
def default_sets
  @sets = 'g2,g3'
end
  
def initAttributeSearch(word_modifier)
  if word_modifier == "1"
    containsQuote = @query[0].index('"')
    lastQuote = @query[0].rindex('"')
    if containsQuote==nil || lastQuote!=@query[0].length-1
      containsQuote = @query[0].index('&quot;')
      lastQuote = @query[0].rindex('&quot;')
      if containsQuote==nil || lastQuote!=@query[0].length-1
        @query[0]='"' + @query[0] + '"'
      end
    end
  else
    if word_modifier == "2"
      containsOr = @query[0].index(" or ")
      if containsOr==nil 
        newString = ""
        stringArray = @query[0].split(" ")
        iterate=stringArray.length-1
        iterate.times do |i|
          newString = newString + stringArray[i] + " or "
         end
        newString = newString + stringArray[stringArray.length-1]
        @query[0]=newString
      end
    end
  end
end

def filter_results
  if @filter!=nil and @filter!="" and @results!=nil and !@filter.empty?
    for filter_pair in @filter
      if filter_pair!=nil and !filter_pair.empty?
        filter_type=filter_pair[0].to_s
        filter_value=filter_pair[1].to_s
        @results.delete_if {|_record| _record.send(filter_type)==nil or !_record.send(filter_type).downcase.include?(filter_value.downcase)}
      end
    end
  end  
  if @results==nil or @results.empty?
    flash.now[:notice]="Your filter did not match any results"
  end
end

  
def filter_images
  if @results!=nil
    @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
    if @tab_template!=@config["IMAGES_TEMPLATE"]
      found_first=false
      filtered_results=Array.new
      for record in @results
        if record.material_type.downcase=="image"
          if !found_first
            found_first=true
            filtered_results<<record
          end
        else
          filtered_results<<record
        end 
      end
      @all_results=@results
      @results=filtered_results
    end
  end
end
  
  
def  sort_results
  for record in @results
    diff=8-record.date.length
    if diff > 0
      padding="0"*diff
      record.date=record.date+padding
    end
  end
  if @sort_value=='relevance' or @sort_value==nil or @results==nil
    @results.sort!{|a,b| b.rank.to_f <=> a.rank.to_f} 
  else
    if @sort_value=="dateup"
      #Using 500-rank so that results are displayed with highest rank first
      @results=@results.sort_by{|a| [a.date, 500-a.rank.to_f] }      
    else
      #using 100000000-date so that dates are displayed with highest first
      @results=@results.sort_by{|a| [100000000-a.date.to_i, 500-a.rank.to_f] }      
    end
  end
end

def image_tooltip
  _id = params[:id]
  @selected_image=nil
   id = params[:id]
  @selected_image=$objDispatch.GetId(id.gsub("_") {";"}) 
  @selected_image.id.gsub!(";") {"_"}
  strip_quotes(@selected_image)
  if @selected_image==nil
    flash.now[:notice]="Image not found"     
  else
    render(:layout=>false)
  end
end
 
def show_citation
  id = params[:id]
  @record_for_citation=$objDispatch.GetId(id.gsub("_") {";"}) 
  @record_for_citation.id.gsub!(";") {"_"}
  strip_quotes(@record_for_citation)
  @record_for_citation
  render(:layout=>false)  
end
 
def spell_check
  #todo - when we implement advanced search with more than 1 query term, we'll need to change this
  #_word=the array of query terms the user entered to be spell-checked
  _query=@query[0].to_s
  _attribute_list = ["su:","subject:","au:","author:","ti:","title:"]
  #strip out any 'or' or 'and' from the query before getting spelling suggestions
  _query = _query.gsub(" or ", " ")
  _query = _query.gsub(" and ", " ")
  #strip any attribute shortcuts out of query before getting spelling suggestions
  _attribute=""
  for _att in _attribute_list
    if _query.include? _att
      _query=_query.gsub(_att,"")
      _attribute=_att
      break
    end
  end
  @spelling_list=Array.new
  if _query!=nil and _query!=''
    _google_spell = GoogleSpell.new
    #_words=the wordlist of corrected words from google
    _words = _google_spell.GetWords(_query)
    if _words!=nil and !_words.empty?     
      _length=1
      _temp = Array.new
      #This routine figures out how many suggestions to present to user
      _no_suggestions=true
      for _n in 0.._words.length-1 
        if _words[_n]['data'].empty?
           _temp[_n] = _words[_n]['original'].to_a
        else
          _no_suggestions=false
          _temp[_n] = _words[_n]['data'].split(/\t/)
        end
        _length=_length*_temp[_n].length
      end
      if _no_suggestions
        return
      end
     #@spelling_list contains the list of combined suggestions to present to user
      #this routine iterates through all suggestions from google and creates all possible combinations to present to user
      #_i is the column and _j is the row for _temp
      
      for _i in 0.._temp.length-1
        if _temp!=nil and _temp[_i]!=nil and _temp[_i].length>0
        _count=0
        _j=0
        while _count<_length
          #_rep is the number of repetitions for each word to be placed in the array
          _rep=1
          for _m in _i+1.._temp.length-1
            _rep=_rep*_temp[_m].length
          end
          _rep=_rep-1
          for _k in 0.._rep
            if @spelling_list[_count]==nil
              @spelling_list[_count]=_attribute+_temp[_i][_j].to_s
            else
              @spelling_list[_count]=@spelling_list[_count]+" "+_temp[_i][_j].to_s
            end
            _count=_count+1
          end  #end for
          if _j==(_temp[_i].length)-1
            _j=0
          else 
            _j=_j+1
          end
        end    #end for 
      end    #end if
    end      #end for
  end      #end if
end        #end if
rescue
    #ignore spelling errors?
end          #end def
       
      
      
end
