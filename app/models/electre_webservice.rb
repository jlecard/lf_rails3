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
#  _____________________________
# |                             |
# | Class handle WebService :-) |
# |___________________________Jb|
#
require 'xml'
require 'net/http'
require 'uri'
require "base64"

require 'amazon/aws/search' 
require 'amazon/aws'
require 'isbn/tools'
include ISBN_Tools
include Amazon::AWS
include Amazon::AWS::Search

class ElectreWebservice < ActionWebService::Struct
  member :token,      :string
  member :controlErr, :string
  attr_accessor :logger
  
  yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
  #PROXY_HTTP_VARIABLE
  PROXY_HTTP_ADR    = yp['PROXY_HTTP_ADR']
  PROXY_HTTP_PORT   = yp['PROXY_HTTP_PORT']
  PROXY_HTTP_LOGIN  = yp['PROXY_HTTP_LOGIN']
  PROXY_HTTP_PWD    = yp['PROXY_HTTP_PWD']
  WS_USERNAME       = yp['WS_USERNAME']
  WS_PASSWORD       = yp['WS_PASSWORD']
  
  @@DEFAULT_IMAGE_BINARY = nil
  
  def initialize(logger=nil)
    super
    @logger = logger
    if @@DEFAULT_IMAGE_BINARY.nil?
      @logger.debug("[Webservice] [initialize] read default image")
      File.open(DEFAULT_IMAGE, "rb") do |f|
        @@DEFAULT_IMAGE_BINARY = f.read
      end 
    end
  end
  
  def dealing(service, nameFunction, hash_params)
    begin
      if (!PROXY_HTTP_ADR.blank?)
        @logger.debug("[Webservice] [dealing] using proxy: #{PROXY_HTTP_ADR}:#{PROXY_HTTP_PORT}")
        @logger.debug("[Webservice] [dealing] proxy login: #{PROXY_HTTP_LOGIN}")
        @logger.debug("[Webservice] [dealing] hash_params: #{hash_params.inspect}")
        proxy = Net::HTTP::Proxy(PROXY_HTTP_ADR, PROXY_HTTP_PORT, PROXY_HTTP_LOGIN, PROXY_HTTP_PWD)
        ret   = proxy.post_form(URI.parse('http://www.electre.com/WebService/' + service + '.asmx/' + nameFunction), hash_params)
        return ret.body
      else
        ret = Net::HTTP.post_form(URI.parse('http://www.electre.com/WebService/' + service + '.asmx/' + nameFunction), hash_params)
        return ret.body
      end
    rescue => err
      @logger.error("[Webservice] [dealing] erreur appel : #{err.message}")
      @logger.debug("[Webservice] [dealing] erreur backtrace : #{err.backtrace.join("\n")}")
      return ""
    end
  end
  
  def parseISBN(isbn)
    if isbn.blank?
      return isbn
    else
      return isbn.gsub("-","").gsub(" ","")
    end
  end
  
  def getNodeContent(xml, typeNamespace="//xmlns:string")
    begin
      @logger.debug("[webservice] [getNodeContent] xml : #{xml}")
      if (xml.nil?)
        return nil
      end
      case ::PARSER_TYPE
        when 'libxml'
        parser  = LibXML::XML::Parser.string(xml)
        doc     = LibXML::XML::Document.new
        doc     = parser.parse
        return (doc.last())
        when 'nokogiri'
        doc = Nokogiri::XML.parse(xml)
        values = doc.xpath(typeNamespace)
        values.each do |v|
          return v
        end
      end
      
    rescue => err
      @logger.error("[webservice] [getNodeContent] erreur on parsing xml : #{err.message}")
      @logger.debug("[webservice] [getNodeContent] erreur on parsing xml : #{err.backtrace}")
    end
    return nil
  end
  
  
  def logon
    begin
      identifiant = {'userName' => WS_USERNAME, 'userPassword' => WS_PASSWORD}
      xml         = dealing('login', 'loginUser', identifiant)
      node        = getNodeContent(xml)
      self.token  = node.content
      
      return node.content
    rescue => err
      @logger.error("[Webservice] [logon] erreur appel : #{err.message}")
      @logger.error("[Webservice] [logon] html received : #{xml}")
      return nil
    end
  end
  
  def logout(token)
    begin
      session = {'sessionIdCookie' => "#{token}"}
      ret     = dealing('login', 'logoutUser', session)
      return ret
    rescue => err
      @logger.error("[Webservice] [logout] erreur appel : #{err.message}")
      @logger.error("[Webservice] [logout] html received : #{ret}")
      return ""
    end
  end
  
  def getSessionToken()
    begin
      identifiant = {'login' => WS_USERNAME, 'password' => WS_PASSWORD}
      xml         = dealing('login', 'getSessionTokens', identifiant)
      @logger.debug("[Webservice] [getSessionTokens] html received : #{xml}")
      node        = getNodeContent(xml)
      content     = nil
      @logger.debug("[Webservice] [getSessionTokens] Node : #{node.inspect}")
      if (!node.nil? and !node.content.nil?)
        content = node.content.split("\n")[-1]
      else
        content = logon
      end
      @logger.debug("[Webservice] [getSessionTokens] Token : #{content}")
      self.token = content
      return self.token
    rescue => err
      @logger.error("[Webservice] [getSessionTokens] call error : #{err.message}")
      @logger.debug("[Webservice] [getSessionTokens] stack trace : #{err.backtrace.join("\n")}")
      @logger.error("[Webservice] [getSessionTokens] html received : #{xml}")
      return nil
    end
  end
  
  def checkToken
    begin
      if (self.token.nil?)
        self.token = getSessionToken
      end
    rescue => err
      @logger.error("[Webservice] [checkToken] Error on :  #{err.message}")
    end
  end
  
  def back_cover(isbn)
    begin
      if ((isbn.nil?) || (isbn.blank?))
        return ""
      end
      isbn = parseISBN(isbn)
      checkToken()
      identifiant = {'sessionToken' => "#{self.token}", 'ean' => "#{isbn}"}
      xml         = dealing('search','getQuatriemeXml', identifiant)
      node        =  getNodeContent(xml)
      ret         = node.content
      @logger.debug("[webservice] [back_cover] ret : #{ret}")
      return (ret)
    rescue => err
      @logger.error("[Webservice] [getQuatriemeXml] erreur appel :  #{err.message}")
      @logger.error("[Webservice] [getQuatriemeXml] html received :  #{xml}")
      return ""
    end
  end
  
  def table_of_contents(isbn)
    begin
      if ((isbn.nil?) || (isbn.blank?))
        return ""
      end
      isbn = parseISBN(isbn)
      checkToken()
      identifiant = {'sessionToken' => "#{self.token}", 'ean' => "#{isbn}"}
      xml   = dealing('search','getTdmXml', identifiant)
      node  = getNodeContent(xml)
      ret   = node.content
      @logger.debug("[webservice] [table_of_contents] ret : #{ret}")
      return ret
    rescue => err
      @logger.error("[Webservice] [tableDesMatieres] call error :  #{err.message}")
      @logger.error("[Webservice] [tableDesMatieres] html received :  #{xml}")
      return ""
    end
  end
  
  def image(isbn)
    begin
      logger.debug("[WebService] getImage for isbn : #{isbn}")
      if ((isbn.nil?) || (isbn.blank?))
        return ("")
      end
#      isbn = parseISBN(isbn)
#      logger.debug("[WebService] getImage for isbn after parse: #{isbn}")
#      checkToken
#      identifiant = {'sessionCookie' => "#{self.token}", 'ean' => "#{isbn}", 'scaled' => true}
#      xml         = dealing('search','getImage', identifiant)
#      node        = getNodeContent(xml, "//xmlns:base64Binary")
#      ret         = node.content
#      
#      if (!ret.blank?)
#        return(Base64.decode64(ret))
#      else
#        logger.debug("[WebService] getImage default ")
#        return("")
#      end

      if ISBN_Tools.is_valid_isbn13?(isbn)
        isbn = ISBN_Tools.isbn13_to_isbn10(isbn)
        @logger.debug("Invalid ISBN: #{isbn}")
      elsif !ISBN_Tools.is_valid_isbn10?(isbn)
        @logger.debug("Invalid ISBN: #{isbn}")
        return ""
      end
      isbn.gsub!("-","")
      il = ItemLookup.new( 'ASIN', { 'ItemId' => isbn } ) 
      req = Request.new 
      resp = req.search( il ) #, rg ) 
      item = resp.item_lookup_response.items.item
      image_url = nil
      if item
        if !item.medium_image.nil? 
          image_url = item.medium_image.url.to_s
        elsif !item.small_image.nil?
          image_url = item.small_image.url.to_s
        elsif !item.large_image.nil?
          image_url = item.large_image.url.to_s
        else  
          return ""
        end
      
      #@logger.debug("AMAZON WEBSERVICE REQUEST ITEM: #{item.inspect}")     
        if (!PROXY_HTTP_ADR.blank?)
          @logger.debug("[Webservice] [dealing] using proxy: #{PROXY_HTTP_ADR}:#{PROXY_HTTP_PORT}")
          @logger.debug("[Webservice] [dealing] proxy login: #{PROXY_HTTP_LOGIN}")
          proxy = Net::HTTP::Proxy(PROXY_HTTP_ADR, PROXY_HTTP_PORT, PROXY_HTTP_LOGIN, PROXY_HTTP_PWD)
          ret   = proxy.get(URI.parse(image_url))
        else
          ret = Net::HTTP.get(URI.parse(image_url))
        end
      end
      if (!ret.blank?)
        return ret
      else
        logger.debug("[WebService] getImage default ")
        return("")
      end
    rescue => err
      @logger.error("[Webservice] [getImage] error Message :  #{err.message}")
      @logger.debug("[Webservice] [getImage] error backtrace #{err.backtrace.join("\n")}")
    end 
    return ("")
  end
  
  def image?(isbn)
    begin
      if ((isbn.nil?) || (isbn.blank?))
        return ("")
      end
#      isbn = parseISBN(isbn)
#      checkToken()
#      identifiant = {'sessionCookie' => "#{self.token}", 'ean' => "#{isbn}", 'scaled' => true}
#      xml         = dealing('search','getImage', identifiant)
#      node        = getNodeContent(xml, "//xmlns:base64Binary")
#      ret         = node.content
      
      #if ((!ret.nil?) && (!ret.blank?))
        return true
      #end
      #return false
    rescue => err
      @logger.error("[Webservice] [image?] call error  : #{err.message}")
      @logger.error("[Webservice] [image?] html received : #{ret}")
      return false
    end
  end
end
