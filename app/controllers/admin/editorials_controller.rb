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
class Admin::EditorialsController < ApplicationController
  
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
  
  def index
    @editorials = Editorial.find(:all)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @editorials }
    end
  end
  
  def show
    @editorial = Editorial.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @editorial }
    end
  end
  
  def new
    @editorial = Editorial.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @editorial }
    end
  end
  
  def edit
    @editorial = Editorial.find(params[:id])
  end
  
  def create
    @editorial = Editorial.new(params[:editorial])
    
    respond_to do |format|
      if @editorial.save
        flash[:notice] = 'Editorial was successfully created.'
        format.html { redirect_to(:action => "index") }
        format.xml  { render :xml => @editorial, :status => :created, :location => @editorial }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @editorial.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @editorial = Editorial.find(params[:id])
    
    respond_to do |format|
      if @editorial.update_attributes(params[:editorial])
        flash[:notice] = 'Editorial was successfully updated.'
        format.html { redirect_to(:action => "index") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @editorial.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @editorial = Editorial.find(params[:id])
    @editorial.destroy
    
    respond_to do |format|
      format.html { redirect_to(admin_editorials_url) }
      format.xml  { head :ok }
    end
  end
  
  def affecte
    
    @collection_groups = CollectionGroup.find(:all)
    @editorials = Editorial.find(:all, :order => :id)
    
    @selected_collections = []
    @selected_editorials_rank = []
    @collection_group = CollectionGroup.new()
    @collection_group.id = 0
    
    if !params[:collection_group_id].blank?
      
      id = params[:collection_group_id].to_i
      
      @collection_groups.each do |c| 
        if c.id == id
          @collection_group = c
          if !@collection_group.editorial_group_members.blank? and !@collection_group.editorial_group_members.empty?
            sorted_collections=@collection_group.editorial_group_members.sort_by{ |col| col.editorial_id }
            
            @selected_editorials = Array.new(@collection_group.editorial_group_members.length) { |i|
              sorted_collections[i].editorial_id.to_s
            }
            
            @selected_editorials_rank = Array.new(@collection_group.editorial_group_members.length) { |i|
              sorted_collections[i].rank.to_s
            }
          end
        end
      end
    end 
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @collection_groups }
    end
    
  end
  
  def maj
    
    id = params[:collection_group_id]
    if !id.blank? and id.to_i > 0 and !params[:editorials].nil?
      
      @selected_editorials = []
      
      params[:editorials].each do |k,v|
        if v == "1"
          @selected_editorials << k
        end
      end
      
      @collection_group = CollectionGroup.find(id)
      
      if @collection_group.editorials != nil and !@collection_group.editorials.empty?
        
        old_editorial_list=Array.new(@collection_group.editorials.length) {|i|@collection_group.editorials[i].id.to_s}
        removed_collections=old_editorial_list-@selected_editorials
        for e in removed_collections
          EditorialGroupMember.delete_all(["editorial_id = :eid and collection_group_id = :cgid", {:eid => e.to_i, :cgid => id.to_i}])
        end
      end
      
      for id_e in @selected_editorials
        editorial=Editorial.find(id_e.to_i) 
        egm = nil
        
        if !@collection_group.editorials.include? editorial
          egm = EditorialGroupMember.new 
          egm.editorial = editorial
          egm.collection_group = @collection_group
        else
          arr = EditorialGroupMember.find(:all, :conditions => ["editorial_id = :eid and collection_group_id = :cgid", {:eid => editorial.id.to_i, :cgid => id.to_i}])
          arr.each do |v|
            egm = v
          end
        end
        
        params[:ranks].each do |k,v|
          if k.to_i == editorial.id
            egm.rank = v.to_i
          end
        end
        
        egm.save!
      end
      
    else
      @collection_group = CollectionGroup.new
      @collection_group.id = 0
    end
    
    respond_to do |format|
      format.html { redirect_to(:action => "affecte",:collection_group_id => @collection_group.id ) }
      format.xml  { render :xml => :ok }
    end
  end
end
