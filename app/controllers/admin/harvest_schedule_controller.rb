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

class Admin::HarvestScheduleObject
  attr_accessor :id, :collection_id, :collection_name, :collection_alt_name
end

class Admin::HarvestScheduleController < ApplicationController
  include ApplicationHelper
  
  layout 'admin'
  auto_complete_for :collection, :name, {:conditions=>"conn_type NOT IN ('z3950', 'sru','opensearch')"}
  before_filter :authorize, :except => 'login',
  :role => 'administrator', 
  :msg => 'Access to this page is restricted.'
  
  def initialize
    super
  end
  
  def new
    load_unharvested_collections
    @harvest_schedule = HarvestSchedule.new
  end
  
  def index
    list
    render :action => :list
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :destroy, :create, :update ],
  :redirect_to => { :action => :list }
  
  def list
    @harvest_schedule = HarvestSchedule.find(:all)
  end
  
  def show
    
  end
  
  def create
    back_to_collection = params['back_to_collection']
    @harvest_schedule = HarvestSchedule.new
    key = params[:harvest_schedule]['day']
    day = @harvest_schedule.enum_values[key.to_i-1][1]
    hour = params[:harvest_schedule]["time(4i)"].to_i
    minutes = params[:harvest_schedule]["time(5i)"].to_i
    _time = Time.parse("#{hour}:#{minutes}")
    @harvest_schedule.time = _time
    @harvest_schedule.day = day
    collection_id = Collection.find_by_name(params[:collection][:name]).id
    @harvest_schedule.collection_id = collection_id 
    if @harvest_schedule.save
      flash[:notice] = translate('HARVEST_SCHEDULE_CREATED')
      if back_to_collection != "true"
        redirect_to :action => 'list'
      else
        redirect_to :controller=>'admin/collection', :action => 'edit', :params=>{'id'=>collection_id}
      end
    else
      render :action => 'new', :params=>params
    end
  end
  
  def edit
    load_unharvested_collections
    condition = "day = '#{params[:day]}' and TIME_FORMAT(time,'%H:%i') = '#{params[:time]}'"
    @harvest_schedules = HarvestSchedule.find(:all, {:conditions=>condition})
  end
  
  def update
    load_unharvested_collections
    if !params[:remove].nil?
      collection_to_remove = params[:remove]
      ar_params = collection_to_remove.split('__')
      collection_id = ar_params[1].to_i
      schedule_id = ar_params[2].to_i
      begin
        schedule = HarvestSchedule.find_by_id_and_collection_id(schedule_id, collection_id)
        schedule.destroy
        return render :text => ar_params[1].to_json
      rescue Exception => e
        raise e
        return
      end
    elsif !params[:add].nil?
      begin
        collection_to_add = params[:add]
        collection_id = Collection.find_by_name(collection_to_add).id
        schedule = HarvestSchedule.new(:day=>params[:day].to_s, :time=>params[:time],
                                       :collection_id=>collection_id.to_i )
        raise Exception.new("Validation failed : day, time and collection already exists") if !schedule.save
        
        condition = "day = '#{params[:day]}' and TIME_FORMAT(time,'%H:%i') = '#{params[:time]}'"
        harvest_schedules = HarvestSchedule.find(:all, :conditions=>condition, :include=>:collection )
        arr = Array.new
        harvest_schedules.each do |sched|
          obj = Admin::HarvestScheduleObject.new 
          obj.id = sched.id
          obj.collection_id = sched.collection_id
          obj.collection_name = sched.collection.name
          arr.push(obj)
        end
        return render :json => arr
      rescue Exception => e
        return render :json => "Error adding collection : #{e.message}"
      end
    end
    
  end
  
  def destroy
    HarvestSchedule.find(params[:id].to_i).destroy
    redirect_to :action => 'list'
  end
  
  # Returns the name of the collection provided its id 
  def ajax_collection_name
    name = Collection.find_by_id(params[:id].to_i).name
    return render :text => Collection.find_by_id(params[:id].to_i).name
  end
  
  def unharvested
    load_unharvested_collections
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :json => @unharvested_collections
  end
  
  # Returns the lsit of collections that are never harvested
  def load_unharvested_collections
    where_clause = "(id NOT IN (SELECT collection_id from harvest_schedules))
    AND (conn_type NOT IN ('z3950', 'sru','opensearch'))" 
    @unharvested_collections = Collection.find(:all, {:conditions=>where_clause})
  end
  
  def display_log
    begin
      log_path = "#{RAILS_ROOT}/log/harvesting_log.txt"
      send_file log_path, :type => 'text/html; charset=utf-8'#, :disposition => 'inline'
    rescue => e
      headers["Content-Type"] = "text/plain; charset=utf-8"
      return render :json => "Error when display log : #{e.message}"
    end
  end
end
