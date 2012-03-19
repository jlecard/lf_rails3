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
class DocumentController < ApplicationController
  require 'timeout'
  
  layout 'libraryfind'
  include ApplicationHelper
  include DocumentHelper
  include CartHelper 
  
  def display
    if params[:print]
      printpage
    end
    ###################################
    # id[0] : idDoc
    # id[1] : idCollection
    # id[2] : idSearch
    ###################################
    seek = SearchController.new();
    @filter_tab = seek.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = seek.load_groups;
    
    begin
      paginate_cart(2)
    rescue
      logger.debug("no cookie found !")
    end
    
    if !params[:doc].nil?
      id = params[:doc].split(ID_SEPARATOR)
    else
      logger.warn("[display] no id for doc")
      return
    end
    
    doc = MetaDisplay.new
    begin
      @record = doc.display(id[0], id[1], id[2])
      if !@record.nil?
        if ((@record[:isbn] != nil) && (@record[:isbn] != ''))
          isbn = @record[:isbn]
          if (isbn != nil)
            isbn = isbn.gsub("-", "")
          end
          moreInfo(isbn)
        end
        @id = @record.id
        @id_format = @id.gsub(";","").gsub("/","").gsub(":","")
        
        @sourceDetails = doc.getMediaviewDocument(id[0], id[1], id[2])
        
        if !@sourceDetails.nil?
          
          @objectType = @sourceDetails.object
          
          if @objectType == "Web"
            @source = @sourceDetails.sourceUrl
          else
            @source = @sourceDetails.source
          end
        end 
        
      else
        logger.warn("[display] Record nil for #{id}")
      end
    rescue => e     
      logger.error("[DocumentController] [display] Error displaying detailed document #{e.message}")
      logger.error("[DocumentController] [display] error : #{e.backtrace.join('\n')}")
    end   
  end
  
  def printpage
    #render :layout => false
    doc = MetaDisplay.new
    begin
      _id = params[:doc].split(ID_SEPARATOR)
      items = {:idDoc => "#{params[:doc]}", :host => "#{request.remote_addr}"};
      LogGeneric.addToFile("LogPrintUsage", items);
      #logger.debug("id = " + _id.to_s)
      @record_found = doc.display(_id[0], _id[1], _id[2])
    rescue
      logger.debug("Error displaying print preview")
    end
  end
  
  def refworks
    doc = MetaDisplay.new
    begin
      _id = params[:doc].split(ID_SEPARATOR)
      #      items = {:idDoc => "#{params[:id]}", :host => "#{request.remote_addr}"};
      #      LogGeneric.addToFile("LogPrintUsage", items);
      recordTmp = doc.display(_id[0], _id[1], _id[2])
      datas = []
      
      if recordTmp[:atitle] != ""
        datas.push("T1" => recordTmp[:atitle])
      end
      if recordTmp[:isbn] != ""
        datas.push("SN" => recordTmp[:isbn])
      end
      if recordTmp[:issn] != ""
        datas.push("SN" => recordTmp[:issn])
      end
      if recordTmp[:abstract] != ""
        datas.push("AB" => recordTmp[:abstract])
      end
      if recordTmp[:date] != ""
        datas.push("FD" => recordTmp[:date])
      end
      if recordTmp[:author] != ""
        datas.push("A1" => recordTmp[:author])
      end
      if recordTmp[:link] != ""
        datas.push("LK" => recordTmp[:link])
      end
      if recordTmp[:direct_url] != ""
        datas.push("LK" => recordTmp[:direct_url])
      end
      if recordTmp[:static_url] != ""
        datas.push("LK" => recordTmp[:static_url])
      end
      if recordTmp[:subject] != ""
        datas.push("DS" => recordTmp[:subject])
      end
      if recordTmp[:publisher] != ""
        datas.push("PB" => recordTmp[:publisher])
      end
      if recordTmp[:contributor] != ""
        datas.push("A2" => recordTmp[:contributor])
      end
      if recordTmp[:callnum] != ""
        datas.push("AN" => recordTmp[:callnum])
      end
      # Must be 0 if Print or 1 is Electronic
      #        if recordTmp[:material_type] != ""
      #           datas.push("SR" => recordTmp[:material_type])
      #        end
      #        if recordTmp[:format] != ""
      #           datas.push("" => recordTmp[:format])
      #        end
      #        if recordTmp[:theme] != ""
      #           datas.push("" => recordTmp[:theme])
      #        end
      #        if recordTmp[:category] != ""
      #           datas.push("" => recordTmp[:category])
      #        end
      #        if recordTmp[:vendor_name] != ""
      #           datas.push("" => recordTmp[:vendor_name])
      #        end
      #        if recordTmp[:vendor_url] != ""
      #           datas.push("" => recordTmp[:vendor_url])
      #        end
      if recordTmp[:volume] != ""
        datas.push("VO" => recordTmp[:volume])
      end
      if recordTmp[:issue] != ""
        datas.push("IS" => recordTmp[:issue])
      end
      if recordTmp[:number] != ""
        datas.push("AN" => recordTmp[:number])
      end
      if recordTmp[:page] != ""
        datas.push("SP" => recordTmp[:page])
      end
      if recordTmp[:raw_citation] != ""
        datas.push("CR" => recordTmp[:raw_citation])
      end
      if recordTmp[:oclc_num] != ""
        datas.push("ID" => recordTmp[:oclc_num])
      end
      
      # The first element MUST be the RT Tag !!
      # TODO Faire correspondre le type de la notice avec la liste des TAG autorisés par RefWorks
      @val = "RT Book, Section\n"
      @val += "UL #{::LIBRARYFIND_BASEURL + request.request_uri[1,request.request_uri.length].to_s}\n"
      datas.each {|item|
        @val += "\n"
        item.each {|key, value|
          @val += "#{key} #{value}"
        }
      }
    rescue
      logger.debug("Error displaying print preview")
    end
  end
  
  def build_document_contents(id)
    
    #if session[:document]!=nil && !session[:document].empty?
    #for _id in session[:document]
    doc = MetaDisplay.new
    begin
      _id = id.split(ID_SEPARATOR) 
      logger.debug("id = " + _id.to_s) 
      @record = doc.display(_id[0], _id[1], _id[2])
    rescue
      logger.debug("Error displaying detailed document")
    end
    #end
    #    else
    #      logger.debug('Error in email')
    #    end
  end
  
  def email
    regex = Regexp.new('[\w\-_]+[\w\.\-_]*@[\w\-_]+\.[a-zA-Z\-_]{2,4}')
    match = regex.match(params[:to])
    if match
      _email_address = params[:to]
      _id = params[:doc].to_s.gsub("/", "_")
      items = {:idDoc => "#{_id}", :host => "#{request.remote_addr}"};
      LogGeneric.addToFile("LogMailUsage", items);
      begin
        logger.debug('id_for_email:' + _id)
        build_document_contents(_id)
        _email = DocumentMailer.create_results(@record, _email_address) 
        _email.set_content_type("text/html")
        DocumentMailer.deliver(_email)
        flash.now[:notice]=translate('EMAIL_SENT')
        logger.debug("Email working")
      rescue Timeout::Error => time
        flash.now[:error]=translate('EMAIL_NOT_SENT')
        logger.error("Error sending mail #{$!}" + time.message)
      rescue => err
        flash.now[:error]=translate('EMAIL_NOT_SENT')
        logger.error("Error sending mail #{$!}" + err.message)
      end
    else
      flash.now[:error]=translate('EMAIL_FORMAT_ERROR')
      logger.error("Error in mail adress #{$!}")
    end
    render :layout => false
  end
  
end