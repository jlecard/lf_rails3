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
class Admin::SearchTabFiltersController < ApplicationController
  layout 'admin'
  before_filter :authorize, :except => 'login',
                :role => 'administrator',
                :msg => 'Access to this page is restricted.'
  
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = seek.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = seek.load_groups;
  end
                
  # GET /admin_search_tab_filters
  # GET /admin_search_tab_filters.xml
  def index
    @admin_search_tab_filters = SearchTabFilter.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @admin_search_tab_filters }
    end
  end

  # GET /admin_search_tab_filters/1
  # GET /admin_search_tab_filters/1.xml
  def show
    @search_tab_filter = SearchTabFilter.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @search_tab_filter }
    end
  end

  # GET /admin_search_tab_filters/new
  # GET /admin_search_tab_filters/new.xml
  def new
    @search_tab_filter = SearchTabFilter.new
    @fields_filter = @search_tab_filter.getFields()
    @search_tabs = SearchTab.find(:all)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @search_tab_filter }
    end
  end

  # GET /admin_search_tab_filters/1/edit
  def edit
    @search_tab_filter = SearchTabFilter.find(params[:id])
    @fields_filter = @search_tab_filter.getFields()
    @search_tabs = SearchTab.find(:all)
  end

  # POST /admin_search_tab_filters
  # POST /admin_search_tab_filters.xml
  def create
    @search_tab_filter = SearchTabFilter.new(params[:search_tab_filter])

    respond_to do |format|
      if @search_tab_filter.save
        flash[:notice] = 'SearchTabFilter was successfully created.'
        format.html { redirect_to(:action => 'index') }
        format.xml  { render :xml => @search_tab_filter, :status => :created, :location => @search_tab_filter }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @search_tab_filter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_search_tab_filters/1
  # PUT /admin_search_tab_filters/1.xml
  def update
    @search_tab_filter = SearchTabFilter.find(params[:id])

    respond_to do |format|
      if @search_tab_filter.update_attributes(params[:search_tab_filter])
        flash[:notice] = "Le filtre d'onglet est cree."
        format.html { redirect_to(:action => 'index') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @search_tab_filter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_search_tab_filters/1
  # DELETE /admin_search_tab_filters/1.xml
  def destroy
    @search_tab_filter = SearchTabFilter.find(params[:id])
    @search_tab_filter.destroy

    respond_to do |format|
      format.html { redirect_to(admin_search_tab_filters_url) }
      format.xml  { head :ok }
    end
  end
end
