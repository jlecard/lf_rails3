# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
module SearchHelper
  
  def init_feed_search
    @document_type = params[:document_type];
    @collection_group = params[:collection_group];
  end
  
  def init_search
    @isbn_list = ""
    @image_isbn_list = ""
    setDefaults
    logger.debug(params.to_s)
    initQueryAndType(params)
    if (!params[:query].nil? and params[:query][:mod] != "0") 
      initAttributeSearch(params[:query][:mod])
    end
    if !params[:filter].blank? && !params[:filter].empty?
      @filter=[]
      for filter_pair in params[:filter].to_s.split("/")
        if filter_pair != nil and filter_pair != ""
          @filter << filter_pair.split(FILTER_SEPARATOR)
        end
      end
    end  
    
    if !params[:query].nil? and !params[:query][:max].blank?
      @max = params[:query][:max]
    end
    
    if params[:mobile]!=nil and params[:mobile]=='true'
      @IsMobile = true
    end 
    if session != nil && session[:maxShowResults] != nil
      @page_size = session[:maxShowResults].to_i
    end
    if ((!params.nil?) && (!params[:idTab].nil?))
      @idTab = params[:idTab]
    end
    @relations = []
    if !params[:completed].blank? 
      @completed = params[:completed].split(',')
    end
    if !params[:query].nil? and !params[:query][:mod].blank?
      @mod = params[:query][:mod]
    end 
    if !params[:mode].blank? 
      @mode = params[:mode]
    end 
    if !params[:sort_value].blank?
      @sort_value=params[:sort_value]
    end
    if !params[:query].nil? and !params[:query][:start].blank? 
      @start = params[:query][:start]
    end
    if !params[:tab_template].blank? 
      @tab_template = params[:tab_template]
    end
    if !params[:query_sets].blank?
      @sets=params[:query_sets]
    else
      if (!params[:sets].blank?)
        @sets=params[:sets]
        if (params[:sets].match("widget"))
          @sets= WIDGET_SETS;
        end
      else
        if @sets==nil || @sets.empty?
          init_sets
        end
      end
    end
    if @sets.rindex(',')==@sets.length-1
      @sets=@sets.chop
    end
  end
  
  def init_sets
      begin
        @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
        @sets=""
        groups=@config["DEFAULT_GROUPS"].to_s.split(',')
        for group in groups
          _item = $objDispatch.GetGroupMembers(group)
          @sets = @sets + _item.id + ","
        end
      rescue Exception => e
        logger.error("RecordController caught ERROR: " + e.to_s)
        logger.error(e.backtrace.to_s)
      end
  end    
  
  def setDefaults
    @filter=[]
    @max = getMaxCollectionSearch
    @mod="0"
    @mode="simple"
    @query=[""]
    @sort_value='relevance'
    @start="0"
    @type=["keyword"]
    @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
    @tab_template=@config["GENERAL_TEMPLATE"]
  end
  
  def initQueryAndType(params)
  
    @query=[]
    @type=[]
    @operator=[]
    if !params[:query].nil?
      q  = params[:query][:string]
      t  = params[:query][:type]
      q1 = params[:query][:string1]
      q2 = params[:query][:string2]
      q3 = params[:query][:string3]
      t1 = params[:query][:field_filter1]
      t2 = params[:query][:field_filter2]
      t3 = params[:query][:field_filter3]
      o1 = params[:query][:operator1]
      o2 = params[:query][:operator2]
      
      if !q1.blank?
        @query << q1
        @type << t1
      end
      if !q2.blank?
        if !@query.empty? 
          @operator << o1
        end
        @query  << q2
        @type << t2
      end
      if !q3.blank?
        if !@query.empty? 
          @operator << o2
        end
        @query  << q3
        @type << t3
      end
      if !q.blank?
        if @query.empty?
          @operator << "AND"
        end
          
        @query << q
        @type << t

      end
    end
    
    # set default value if empty
    if @type.empty? or @type =="" or @type.nil?
      @type=["keyword"]
    end
  end
  
  def initAttributeSearch(word_modifier)
    if word_modifier == "1"
      containsQuote = @query[0].to_s.index('"')
      lastQuote = @query[0].to_s.rindex('"')
      if containsQuote==nil || lastQuote!=@query[0].to_s.length-1
        containsQuote = @query[0].to_s.index('&quot;')
        lastQuote = @query[0].to_s.rindex('&quot;')
        if containsQuote==nil || lastQuote!=@query[0].to_s.length-1
          @query[0]='"' + @query[0] + '"'
        end
      end
    else
      if word_modifier == "2"
        containsOr = @query[0].to_s.index(" or ")
        if containsOr==nil
          newString = ""
          stringArray = @query[0].to_s.split(" ")
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
  
  def set_query_values
    @query=params[:query][:string].to_s.split(',')
    @type=params[:query][:type].to_s.split(',')
  end
  
  def defaultNilValues
    for record in @results
      if (!record.nil? and record.class == Record)
        if record.rank==nil
          record.rank='0'
        end
        if record.author==nil
          record.author=""
        end
        if record.date==nil
          record.date='00000000'
        end
      end
    end
  end
end