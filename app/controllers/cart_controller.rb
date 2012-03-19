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
class CartController < ApplicationController
  include ApplicationHelper
  include CartHelper 
  layout "libraryfind", :except => [:message, :add, :remove, :email]
  require 'pdf/writer'
  require 'pdfwriter_extensions'
  
  def add
    id=params[:doc]
    logger.debug("[add] id: #{id}")
    items = {:idDoc=> "#{id}", :host => "#{request.remote_addr}"};
    LogGeneric.addToFile("LogCartUsage", items);
    if !get_cart.include?(id.to_s)
      session[:cart]<<id.to_s
      flash[:notice_r]=translate('ITEM_SAVED')
      render :action=>"message", :controller=>'/cart'
    else
      flash[:error_r]="Notice déjà sauvegardée"
      render :action=>"message", :controller=>'/cart'
    end
  end
  
  def remove
    if session[:cart]!=nil && params[:doc]!=nil && params[:doc]!=''
      session[:cart].delete(params[:doc])
    end
    render :nothing => true
  end
  
  def get_cart
    logger.info(session[:cart].inspect)
    session[:cart] ||= []  
  end
        
  def build_cart_contents(id=nil)
    @cart_contents=[]
    tab = []
    
    if !id.nil?
      tab << id
    elsif session[:cart]!=nil && !session[:cart].empty?
        tab = session[:cart] 
    end
    
    for id in tab
      _result=$objDispatch.GetId(id) 
      if !_result.nil?
        strip_quotes(_result)
        @cart_contents<<_result
      end
    end
  end
  
  def strip_quotes(_record)
    _record.vendor_name.gsub!("'") {""}
    _record.subject.gsub!("'") {""}
    _record.author.gsub!("'") {""}
  end

  def list
    begin
      consult = LogConsult.new
      @mostViewed = consult.topConsulted
    rescue
      @mostViewed = nil
    end
    paginate_cart(2)
  end

   def pdf
   
    begin
      _id = nil
      if !params.nil? and !params[:doc].nil?
        _id = params[:doc]
      end
      
      build_cart_contents(_id)
      
      _pdf = PDF::Writer.new(:paper => "A4")
      
      # Texte
      _pdf.select_font "Times-Roman"
      
  
      _taille = @cart_contents.size
      _cpt = 0
      @cart_contents.each do |_data|
        
         val = ""
         titlePDF = ""
        _data.instance_variables.sort.each do |key|
          value = _data.instance_variable_get(key)
          _key = key.gsub("@","")
          if !value.blank?
            if _key == "ptitle"
              titlePDF = "<b>#{value}</b>\n"
            end
            _key = _key.upcase + "_FIELD"
            _v = translate(_key)
            if _key != _v
              val += "<b>" + translate(_key) + " :</b> #{value}\n\n"
            end
          end
        end
        
        _pdf.text "#{titlePDF}\n\n", :font_size => 25, :justification => :center
        _pdf.text "#{val}\n", :font_size => 10, :justification => :left
        
        _cpt += 1
        
         if _taille > _cpt
          _pdf.start_new_page
        end
      end
      
      
      # Image
      #      img = pdf.image "./moule.jpg", :resize => 0.90
      
      # and we save the file
      
      logger.debug("OK PDF GENERATOR")
      
      send_data _pdf.render, :disposition => 'inline', :filename => "notices.pdf", :type => "application/pdf"  
    rescue => err
      logger.error("Error pdf:" + err.message)
    end
  end
end
