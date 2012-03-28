# $Id: collection_group_controller.rb 1239 2008-03-13 16:55:13Z herlockt $

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

class Admin::CollectionGroupController < ApplicationController
  include ApplicationHelper

  layout 'admin'
  autocomplete :collection_group, :name
  autocomplete :collection_group, :full_name

  before_filter :authorize, :except => 'login',
  :role => 'administrator',
  :msg => 'Access to this page is restricted.'
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => "post", :only => [ :destroy, :create, :update ],
  # :redirect_to => { :action => :list }

  def list
    logger.debug("CollectionGroupController list params = #{params.inspect}")
    conditions = Array.new
    # Filter on the tabs which this collection can be searched from
    conditions.push("(tab_id = #{params[:tab_id_filter][0]})") unless params[:tab_id_filter].nil? or params[:tab_id_filter][0].blank?
    # Filter on the name of the collection
    conditions.push("(name LIKE '#{params[:name]}%')") if params[:name]
    conditions.push("(full_name LIKE '#{params[:full_name]}%')") if params[:full_name]

    where_cond = conditions.join(" AND ").chomp(" AND ")
    @page ||= params[:page] || "1"
    @pages  = CollectionGroup.paginate(:page=>@page,:per_page => 20).where(where_cond).order('name asc')
    @display_columns = ['full_name', 'name']

  end

  def show
    construct_filter_queries
    @display_columns = ['full_name', 'name', 'description', 'display_advanced_search']
    @collection_group = CollectionGroup.find(params[:id].to_i)
    @tab_id_name = "None"
    if @collection_group.tab_id != 0
      tab = SearchTab.find(@collection_group.tab_id)
      if tab != nil
        @tab_id_name = tab.label
      end
    end
  end

  def new
    @collections = Collection.find(:all, :order => 'alt_name asc')
    @collection_group = CollectionGroup.new
    @search_tabs = SearchTab.find(:all)
  end

  def create
    @collection_group = CollectionGroup.new(params[:collection_group])
    if @collection_group.save
      checkboxes=params[:collection]
      if checkboxes!=nil
        ids=""
        for pair in checkboxes
          if pair[1]=='1'
            query_filter = eval("params[:query_collection][\"#{pair[0].to_s}\"]")
            if query_filter != nil || query_filter != ""
              @filter_queries[pair[0].to_s] =  query_filter
            end
            create_group_member(@collection_group,pair[0].to_i,@filter_queries[pair[0].to_s])
          end
        end
      end
      flash[:notice] = translate('COLLECTION_GROUP_CREATED')
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit_groups
    @search_tabs = SearchTab.find(:all)
    construct_filter_queries
    @collections = Collection.find(:all, :order => 'alt_name asc')
    if (params[:id]!=nil && params[:id]!="")
      @collection_group = CollectionGroup.find(params[:id].to_i)
      @collection_group.attributes = (params[:collection_group])
    else
      @collection_group = CollectionGroup.new(params[:collection_group])
    end
    construct_selected_collections
    update_selected_collections
    render :action => 'edit', :id=>@collection_group.id
  end

  def construct_selected_collections
    @selected_collections=[]
    if params[:selected_collections]!=nil && params[:selected_collections]!=""
      @selected_collections=params[:selected_collections].split(',')
    end
    checkboxes=params[:collection]
    if checkboxes!=nil
      for pair in checkboxes
        if (params[:query_collection] != nil)
          query_filter = eval("params[:query_collection][\"#{pair[0].to_s}\"]")
          if query_filter != nil || query_filter != ""
            @filter_queries[pair[0].to_s] =  query_filter
          end
        end
        if pair[1]=='1' && !@selected_collections.include?(pair[0].to_s)
          @selected_collections<<(pair[0].to_s)
        elsif pair[1]=='0' && @selected_collections.include?(pair[0].to_s)
          @selected_collections.delete(pair[0].to_s)
        end
      end
    end
    @selected_collections=@selected_collections.uniq
  end

  def construct_filter_queries
    @filter_queries = Hash.new
    for coll in CollectionGroupMember.find(:all, :conditions => "collection_group_id = #{params[:id]}")
      @filter_queries[coll.collection_id.to_s] = coll.filter_query
    end
  end

  def edit
    construct_filter_queries
    @search_tabs = SearchTab.find(:all)
    @collections = Collection.find(:all, :order => 'alt_name asc')
    @collection_group = CollectionGroup.find(params[:id].to_i)
    @selected_collections = []
    if @collection_group.collections!=nil and !@collection_group.collections.empty?
      sorted_collections=@collection_group.collections.sort_by{ |col| col.alt_name }
      @selected_collections = Array.new(@collection_group.collections.length) {|i|sorted_collections[i].id.to_s}
    end
  end

  def update
    @search_tabs = SearchTab.find(:all)
    construct_filter_queries
    if (params[:id]!=nil && params[:id]!="")
      @collection_group = CollectionGroup.find(params[:id].to_i)
    else
      @collection_group = CollectionGroup.new(params[:collection_group])
    end
    if @collection_group.update_attributes(params[:collection_group])
      construct_selected_collections
      update_selected_collections
      flash[:notice] = translate('COLLECTION_GROUP_UPDATED')
      redirect_to :action => 'edit', :id => @collection_group
    else
      render :action => 'edit'
    end
  end

  def create_group_member(collection_group, collection_id, filter_query)
    collection=Collection.find(collection_id)
    cgm = CollectionGroupMember.new
    cgm.collection = collection
    cgm.collection_group = collection_group
    cgm.default_on = true
    cgm.filter_query = filter_query.nil? ? "" : filter_query
    cgm.save!
  end

  def update_selected_collections
    if (params[:id]!=nil && params[:id]!="")
      @collection_group = CollectionGroup.find(params[:id].to_i)
      if @collection_group.collections!=nil and !@collection_group.collections.empty?
        old_collection_list=Array.new(@collection_group.collections.length) {|i|@collection_group.collections[i].id.to_s}
        removed_collections=old_collection_list-@selected_collections
        for id in removed_collections
          cgm = CollectionGroupMember.find(:first, :conditions =>
          ["collection_id = :cid and collection_group_id = :cgid",
            {:cid => id.to_i, :cgid => @collection_group.id}])
          cgm.destroy
        end
      end
    end
    for id in @selected_collections
      collection=Collection.find(id.to_i)
      if !@collection_group.collections.include? collection
        cgm = CollectionGroupMember.new
        cgm.collection = collection
        cgm.collection_group = @collection_group
        cgm.default_on = true
        cgm.filter_query = @filter_queries[id.to_s] == nil ? "" : @filter_queries[id.to_s]
        cgm.save!
      end
    end
  end

  def destroy
    CollectionGroup.find(params[:id].to_i).destroy
    if params[:id] != ''
      CollectionGroupMember.delete_all( "collection_group_id=" + params[:id].dump)
    end
    redirect_to :action => 'list'
  end
end
