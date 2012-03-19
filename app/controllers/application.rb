# $Id: application.rb 1285 2009-03-02 08:52:34Z reeset $

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

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  
  #after_filter :set_charset
  
  if LIBRARYFIND_WSDL == 1 || LIBRARYFIND_IS_SERVER==true
    require 'record_set'
    require 'rubygems'
    if ::PARSER_TYPE == 'libxml'
      require 'xml/libxml'
	elsif ::PARSER_TYPE == 'nokogiri'
      require 'nokogiri'
    else
      require 'rexml/document'
    end
    require 'meta_search'
    require 'builder'
    #require "mysql"
    require "rzoom"
  end
  
  if LIBRARYFIND_INDEXER.downcase == 'ferret'
    require 'ferret'
  elsif LIBRARYFIND_INDEXER.downcase == 'solr'
    require 'solr'
  end
  require 'dispatch'
  require 'open-uri'
  require 'uri'
  require 'time'
  $objDispatch = Dispatch.new()
  $objCommunityDispatch = CommunityDispatch.new()
  $objAccountDispatch = AccountDispatch.new()

  
  def getMaxCollectionSearch
    _max = MAX_COLLECTION_SEARCH.to_i
    
    if session != nil && session[:maxSearchResults] != nil
      _max = session[:maxSearchResults].to_i
    else
      if params != nil && params[:query] != nil && params[:query][:max] != nil && params[:query][:max] != ""
        _max = params[:query][:max].to_i
      end
    end
    logger.debug("[getMaxCollectionSearch] get: #{_max}")
    return _max 
  end
  
  
  def setGetSessionMaxCollectionSearch
    if params[:max_search].blank?
      if params[:query].blank? or params[:query][:max].blank?
        session[:maxSearchResults] = MAX_COLLECTION_SEARCH
      else
        session[:maxSearchResults] = params[:query][:max].to_i
      end
    else
      if params[:max_search] == 'DEFAULT'
        session[:maxSearchResults] = MAX_COLLECTION_SEARCH
      else   
        session[:maxSearchResults] = params[:max_search].to_i
      end
    end
    logger.debug("[setGetSessionMaxCollectionSearch] set: #{session[:maxSearchResults]}")  
  end
  
  
  def setSessionPagination
    if params[:show_search].blank? or params[:show_search] == 'DEFAULT'
      session[:maxShowResults] = NB_RESULTAT_MAX
    else
      session[:maxShowResults] = params[:show_search].to_i
    end
  end
  
  # change la langue de l'application
  def language
    
    ok = false
    config = YAML::load_file(RAILS_ROOT + "/config/config.yml")
    # vérifie si le paramètre est contenu dans la liste gérée
    config['LANGUAGES'].split(",").each { |v|
      if v == params[:language]
        ok = true
      end
    }
    if ok
      # set dans la session, la langue par defaut
      session[:langue] = params[:language]
    else
      # si code inexistant, set value default
      session[:langue] = config['LANGUAGE']
    end
    
    if !request.nil? and !request.referer.nil?
      redirect_to request.referer
    end
  end
  
  def authorize (role=nil, msg=nil)
    user = User.find_by_id(session[:user_id])
    session[:original_uri] = request.request_uri
    unless user
      logger.debug('UI needing authorization: ' + session[:original_uri])
      flash[:notice] =  msg || translate('PLEASE_LOG_IN')
      redirect_to(:controller => '/user', :action => 'login') and return
    end
    unless role.nil?
      if !user.send(role)
        response.headers["Status"] = "Unauthorized" 
        if msg.blank?
          flash[:notice] = msg || translate('AUTHORIZATION_REQUIRED')
        end
        render :text => msg, :status => 401 and return  
      end
    end
  end
    
  :protected 
  def extract_param(key, classe, default, intInf=0, intSup0=9999999)
    value = default
    begin
      if classe == String && !params[key].blank?
        value =  params[key].to_s
      elsif classe == Integer && !params[key].nil? && params[key].to_i > intInf && params[key].to_i < intSup0
        value =  params[key].to_i
      elsif classe == Array && !params[key].empty?
        value =  params[key].to_a
      elsif classe == DateTime && !params[key].blank?
        value =  params[key]
      else
        value =  default
      end
    rescue => e
      logger.error("[extract_param] #{e.message}")
    end
    return value
  end
  
end
