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
class Admin::PrimaryDocumentTypesController < ApplicationController
  include ApplicationHelper

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

  # GET /primary_document_types
  # GET /primary_document_types.xml
  def index
    @primary_document_types = PrimaryDocumentType.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @primary_document_types }
    end
  end

  # GET /primary_document_types/1
  # GET /primary_document_types/1.xml
  def show
    @primary_document_type = PrimaryDocumentType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @primary_document_type }
    end
  end

  # GET /primary_document_types/new
  # GET /primary_document_types/new.xml
  def new
    @primary_document_type = PrimaryDocumentType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @primary_document_type }
    end
  end

  # GET /primary_document_types/1/edit
  def edit
    @primary_document_type = PrimaryDocumentType.find(params[:id])
  end

  # POST /primary_document_types
  # POST /primary_document_types.xml
  def create
    @primary_document_type = PrimaryDocumentType.new(params[:primary_document_type])

      if @primary_document_type.save
        flash[:notice] = 'PrimaryDocumentType was successfully created.'
        redirect_to :action => 'index'
      else
        render :action => "new"
      end
  end

  # PUT /primary_document_types/1
  # PUT /primary_document_types/1.xml
  def update
    @primary_document_type = PrimaryDocumentType.find(params[:id])

    respond_to do |format|
      if @primary_document_type.update_attributes(params[:primary_document_type])
        flash[:notice] = 'PrimaryDocumentType was successfully updated.'
        format.html { redirect_to(:action => 'index') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @primary_document_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /primary_document_types/1
  # DELETE /primary_document_types/1.xml
  def destroy
    @primary_document_type = PrimaryDocumentType.find(params[:id])
    @primary_document_type.destroy

    respond_to do |format|
      format.html { redirect_to(admin_primary_document_types_url) }
      format.xml  { head :ok }
    end
  end
end
