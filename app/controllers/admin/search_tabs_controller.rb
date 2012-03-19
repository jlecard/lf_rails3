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
class Admin::SearchTabsController < ApplicationController
  layout 'admin'
  before_filter :authorize, :except => 'login',
                :role => 'administrator',
                :msg => 'Access to this page is restricted.'
  # GET /admin_search_tabs
  # GET /admin_search_tabs.xml
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = seek.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = seek.load_groups;
  end
  
  def index
    @search_tabs = SearchTab.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @search_tabs }
    end
  end

  # GET /admin_search_tabs/1
  # GET /admin_search_tabs/1.xml
  def show
    @search_tabs = SearchTab.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @search_tabs }
    end
  end


  # GET /admin_search_tabs/1/edit
  def edit
    @search_tabs = SearchTab.find(params[:id])
  end


  # PUT /admin_search_tabs/1
  # PUT /admin_search_tabs/1.xml
  def update
    @search_tabs = SearchTab.find(params[:id])

    respond_to do |format|
      if @search_tabs.update_attributes(params[:search_tabs])
        flash[:notice] = 'SearchTab was successfully updated.'
        format.html { redirect_to(:action => "index") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @search_tabs.errors, :status => :unprocessable_entity }
      end
    end
  end

end
