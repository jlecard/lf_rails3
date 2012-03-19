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
class Admin::SearchTabSubjectsController < ApplicationController
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
  
  # GET /search_tab_subjects
  # GET /search_tab_subjects.xml
  def index
    @search_tab_subjects = SearchTabSubject.find(:all)
    @search_tabs = SearchTab.find(:all)
    @collection_groups = CollectionGroup.find(:all)
    
    @theme = SearchTabSubject.new();
    @TreeObject = @theme.CreateSubMenuTreeAdmin;
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @search_tab_subjects }
    end
  end
  
  # GET /search_tab_subjects/1
  # GET /search_tab_subjects/1.xml
  def show
    @search_tab_subject = SearchTabSubject.find(params[:id])
    @search_tabs = SearchTab.find(:all)
    @collection_groups = CollectionGroup.find(:all)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @search_tab_subject }
    end
  end
  
  # GET /search_tab_subjects/new
  # GET /search_tab_subjects/new.xml
  def new
    @search_tab_subject = SearchTabSubject.new
    @collection_groups = CollectionGroup.find(:all)
    load_parent_subjects
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @search_tab_subject }
    end
  end
  
  # GET /search_tab_subjects/1/edit
  def edit
    @search_tab_subject = SearchTabSubject.find(params[:id])
    @collection_groups = CollectionGroup.find(:all)
    load_parent_subjects
    
  end
  
  # POST /search_tab_subjects
  # POST /search_tab_subjects.xml
  def create
    @search_tab_subject = SearchTabSubject.new(params[:search_tab_subject])
    @search_tabs = SearchTab.find(:all)
    @collection_groups = CollectionGroup.find(:all)
    
    respond_to do |format|
      if @search_tab_subject.save
        flash[:notice] = 'SearchTabSubject was successfully created.'
        format.html { redirect_to(:action => "index", :id => params[:search_tab_subject][:parent_id]) }
        format.xml  { render :xml => @search_tab_subject, :status => :created, :location => @search_tab_subject }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @search_tab_subject.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /search_tab_subjects/1
  # PUT /search_tab_subjects/1.xml
  def update
    @search_tab_subject = SearchTabSubject.find(params[:id])
    @search_tabs = SearchTab.find(:all)
    @collection_groups = CollectionGroup.find(:all)
    
    respond_to do |format|
      if @search_tab_subject.update_attributes(params[:search_tab_subject])
        flash[:notice] = 'SearchTabSubject was successfully updated.'
        format.html { redirect_to(:action => "index", :id => params[:id]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @search_tab_subject.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /search_tab_subjects/1
  # DELETE /search_tab_subjects/1.xml
  def destroy
    @search_tab_subject = SearchTabSubject.find(params[:id])
    @search_tab_subject.destroy
    @collection_groups = CollectionGroup.find(:all)
    
    respond_to do |format|
      format.html { redirect_to(admin_search_tab_subjects_url + "?id=" + @search_tab_subject.parent_id.to_s) }
      format.xml  { head :ok }
    end
  end
  
  def load_parent_subjects
    @search_tab_subjects = Array.new
    @search_tabs = SearchTab.find(:all)
    @collection_groups = CollectionGroup.find(:all)
    i = 0
    if @search_tabs != nil
      for search_tab in @search_tabs
        @search_tab_subjects[i] = SearchTabSubject.find(:all, :conditions => "tab_id = #{search_tab.id}")
        i = i + 1
      end
    end
    
  end
  
  def hide
    @search_tab_subject = SearchTabSubject.find(params[:id])
    if params[:value] == "true" || params[:value] == "false"
      @search_tab_subject.hide = params[:value]
      @search_tab_subject.save
      @collection_groups = CollectionGroup.find(:all)
      
      respond_to do |format|
        format.html { redirect_to(admin_search_tab_subjects_url + "?id=" + params[:id]) }
        format.xml  { head :ok }
      end
    else
      redirect_to(:action => "index", :id => params[:id])
    end
  end
end
