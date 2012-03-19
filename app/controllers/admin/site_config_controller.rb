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

class Admin::SiteConfigController < ApplicationController

  layout 'admin'
  before_filter :authorize, :except => 'login',
    :role => 'administator', 
    :msg => 'Access to this page is restricted.'
  
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = seek.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = seek.load_groups;
  end

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @site_config_pages, @site_configs = paginate :site_configs, :per_page => 10
  end

  def show
    @site_config = SiteConfig.find(params[:id])
  end

  def new
    @site_config = SiteConfig.new
  end

  def create
    @site_config = SiteConfig.new(params[:site_config])
    if @site_config.save
      flash[:notice] = 'SiteConfig was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @site_config = SiteConfig.find(params[:id])
  end

  def update
    @site_config = SiteConfig.find(params[:id])
    if @site_config.update_attributes(params[:site_config])
      flash[:notice] = 'SiteConfig was successfully updated.'
      redirect_to :action => 'show', :id => @site_config
    else
      render :action => 'edit'
    end
  end

  def destroy
    SiteConfig.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
