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
require 'uri'
require 'net/http'

class SearchController < ApplicationController
  
  def autocomplete
    _sTime = Time.now().to_f
    begin
      word = nil;
      field = nil;
      
      if ((!params[:query].blank?) &&
       (!params[:query][:string].blank?))
        word = params[:query][:string];
      end
      if (!params[:field].blank?)
        field = params[:field];
      end
      @autocomplete_res = $objDispatch.autoComplete(word, field)
      if (@autocomplete_res.blank?)
        raise("error autocomplete empty");
      end
    rescue => e
      logger.debug("ERROR " + e.message)
    end
    logger.debug("#STAT# [AUTOCOMPLETE] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  def aform
    
  end
  
  def load_filter
    @tab_id = SearchTab.find(:all);
    
    @filter_tab = Hash.new();
    @tab_id.each do |elem|
      if (@filter_tab[elem.id] == nil)
        eval ("@filter_tab[:'#{elem.id}'] = Array.new()");
      end
      eval ("@filter_tab[:'#{elem.id}'].push(SearchTabFilter.find(:all, :conditions => 'search_tab_id=#{elem.id}'))");
    end
    return @filter_tab;
  end
  
  def load_menu
    return SearchTab.find(:all);  
  end
  
  def load_groups
    tab = SearchTab.find(:all);
    groups = Array.new();
    
    tab.each do |items|
      if (groups[items.id] == nil)
        eval ("groups[#{items.id}] = Array.new()");
      end
      eval ("groups[#{items.id}] = CollectionGroup.find(:all, :conditions => 'tab_id=#{items.id}', :order => 'rank');")
    end
    return groups;
  end
  
end