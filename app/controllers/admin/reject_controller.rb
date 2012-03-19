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
require 'rexml/document'
require 'rexml/streamlistener'
include REXML
#include StreamListener

class Admin::RejectController < ApplicationController
  
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
    @rejects = Reject.find(:all, :order => "created_at desc");
  end
  
  def index
    render :action => 'showAll'
  end
  
  # View only one error file
  def show
    # Test if GET db exists
    if not params[:id].blank?
      _id = params[:id];
      if (!_id.blank?)
        _content = Reject.find(_id);
        if (!_content.nil?)
          _filename = _content.name + "_" + _content.created_at.strftime("%d%m%y_%H%M") + ".csv"
          send_data(_content.data, :type => 'text/csv', :filename => _filename , :disposition => 'attachment');
        end 
      end
    end
  end
  
end
