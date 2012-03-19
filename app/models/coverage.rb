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

class Coverage < ActiveRecord::Base
  
  def self.search_GR(co)
    require 'net/http'
    require 'uri'
    require 'rexml/document'
    begin
      response = Net::HTTP.get_response(URI.parse(LIBRARYFIND_OPENURL +  co.kev + "&format=xml"))
      doc = REXML::Document.new(response.body)
      if doc.elements["/grlinkerResults/article_access/article_links"] != nil
        target_url = doc.elements["/grlinkerResults/article_access/article_links/link_url"][0].value
        if target_url != nil: return target_url end
      elsif doc.elements["/grlinkerResults/journal_access/resource"] != nil
        target_url = doc.elements["/grlinkerResults/journal_access/resource/resource_url"][0].value
        if target_url != nil: return target_url end
      end
      return nil
    rescue
      return nil
    end
    
  end
  
  def self.search_SFX(co)
    #===============================================
    # We need to take the LIBRARYFIND_OPENURL 
    # address and us that to make an XML search 
    # of the SFX repository.  
    # we parse for service_type = getFullTxt
    # If that is present, we capture the target_url
    #===============================================
    require 'net/http'
    require 'uri'
    require 'rexml/document'
    begin
      response = Net::HTTP.get_response(URI.parse(LIBRARYFIND_OPENURL +  co.kev + "&sfx.response_type=multi_obj_xml"))
      doc = REXML::Document.new(response.body) 
      if doc.elements["/ctx_obj_set/ctx_obj/ctx_obj_targets/target/service_type"] != nil
        service_type = doc.elements["/ctx_obj_set/ctx_obj/ctx_obj_targets/target/service_type"][0].value
        target_url = doc.elements["/ctx_obj_set/ctx_obj/ctx_obj_targets/target/target_url"][0].value
        if service_type == 'getFullTxt': return target_url end
      end
      return nil 
    rescue
      return nil
    end
    
    
  end
  
  def self.search_SS(co)
    #===============================================
    # We need to take the LIBRARYFIND_OPENURL 
    # address and us that to make an XML search 
    # of the SS repository.  
    # we parse for service_type = getFullTxt
    # If that is present, we capture the target_url
    #===============================================
    require 'net/http'
    require 'uri'
    require 'rexml/document'
    begin
      query_string = co.kev.gsub('rft.', ''); 
      response = Net::HTTP.get_response(URI.parse(LIBRARYFIND_OPENURL +  query_string + "&version=1.0"))
      doc = REXML::Document.new(response.body)
      if doc.elements["ssopenurl:openURLResponse/ssopenurl:results/ssopenurl:result/ssopenurl:linkGroups/ssopenurl:linkGroup/ssopenurl:url[@type='article']"] != nil
        target_url = doc.elements["ssopenurl:openURLResponse/ssopenurl:results/ssopenurl:result/ssopenurl:linkGroups/ssopenurl:linkGroup/ssopenurl:url[@type='article']"][0].value
        if target_url != nil
          if target_url != ""
            return target_url;
          else
            return nil
          end 
        else
          return nil
        end
      end
      return nil
    rescue
      return nil
    end
  end
  
  
  def self.search_coverage(co)
    logger.debug("enter search_coverage")
    issn = checknil(co.referent.metadata["issn"]).gsub("-", "")
    essn = checknil(co.referent.metadata["essn"]).gsub("-", "")  
    isbn = checknil(co.referent.metadata["isbn"]).gsub("-", "")
    title = checknil(co.referent.metadata["title"])
    if title=='': title=checknil(co.referent.metadata["jtitle"]) end
    tdate = checknil(co.referent.metadata["date"])
    objRecord = nil
    
    #logger.debug("ready to search")
    if issn!="" && essn != "" 
      objRecord = Coverage.find(:all, :conditions => "issn='#{issn}' OR eissn='#{essn}'")
    elsif essn != ""
      objRecord = Coverage.find(:all, :conditions => "eissn='#{essn}'")
    elsif issn != ""
      objRecord = Coverage.find(:all, :conditions => "issn='#{issn}'")
    elsif isbn != ""
      objRecord = Coverage.find(:all, :conditions => "isbn='#{isbn}'")
    else
      objRecord = Coverage.find(:all, :conditions => "LOWER(journal_title)='#{title}'")
    end
    return nil if objRecord.length == 0
    
    objRecord.each {|_element|
      if _element.start_date !=nil
        start_date = _element.start_date
      else 
        start_date = ""
      end
      
      if _element.end_date !=nil
        end_date = _element.end_date
      else
        end_date = ""
      end
      
      if self.CheckHoldings(tdate, start_date, end_date) == true
        objProvider = Provider.find(:first, :conditions => "provider_name='#{_element.provider}'")
        if objProvider != nil
          if objProvider.can_resolve > 0
            return objProvider
          end  
        end
      end
    }
    return nil
    
  end
  
  def self.processURL(url, co)
    #{TITLE#
    #{SID#
    #{ID#
    #{AULAST#
    #{ISSN#
    #{VOLUME#
    #{ISSUE#
    #{siciDATE#
    #{SPAGE#
    #{YEAR#
    #{ATITLE#
    #{ISSN-HYPHEN#
    #{DATE#
    #{ARTNUM#
    #{AUFIRST#
    #{AUTHOR#
    #{ISBN#
    #{PAGES#
    #{PART#
    #{QUARTER#
    #{SEASON#
    #{GENRE#
    
    title = checknil(co.referent.metadata["jtitle"])
    if title=="": checknil(title = co.referent.metadata["title"]) end
    
    sid = checknil(co.referent.metadata["sid"])
    
    if url.index("{TITLE}")!=nil: url = url.gsub("{TITLE}", URI.escape(title)) end
    if url.index("{SID}")!=nil:  url = url.gsub("{SID}", URI.escape(sid)) end
    if url.index("{ID}")!=nil: url = url.gsub("{ID}", URI.escape(checknil(co.referent.metadata["id"]))) end
    if url.index("{AULAST}")!=nil: url = url.gsub("{AULAST}", URI.escape(checknil(co.referent.metadata["aulast"]))) end
    if url.index("{ISSN}")!=nil:  url = url.gsub("{ISSN}", URI.escape(checknil(co.referent.metadata["issn"]))) end
    if url.index("{VOLUME}")!=nil: url = url.gsub("{VOLUME}", URI.escape(checknil(co.referent.metadata["volume"]))) end
    if url.index("{ISSUE}")!=nil: url = url.gsub("{ISSUE}", URI.escape(checknil(co.referent.metadata["issue"]))) end
    if url.index("{SPAGE}")!=nil:  url = url.gsub("{SPAGE}", URI.escape(checknil(co.referent.metadata["spage"]))) end
    if url.index("{YEAR}")!=nil:  
      tdate = checknil(co.referent.metadata["date"])
      if tdate.length > 4: tdate = tdate.slice(0,4) end
      url = url.gsub("{YEAR}", URI.escape(tdate))
    end
    if url.index("{ATITLE}")!=nil: url = url.gsub("{ATITLE}", URI.escape(checknil(co.referent.metadata["atitle"]))) end
    if url.index("{ISSN-HYPHEN}")!=nil: url = url.gsub("{ISSN-HYPHEN}", URI.escape(checknil(co.referent.metadata["issn"]))) end
    if url.index("{DATE}")!=nil:  url = url.gsub("{DATE}", URI.escape(checknil(co.referent.metadata["date"]))) end
    #if (strpos($url, "{siciDATE}")) {url = str_replace('{siciDATE#', substr(str_replace('-','',$lrequest_array['date']),0,6),$url);}
    if url.index("{ARTNUM}")!=nil: url = url.gsub("{ARTNUM}", URI.escape(checknil(co.referent.metadata["artnum"]))) end
    if url.index("{AUFIRST}")!=nil: url = url.gsub("{AUFIRST}", URI.escape(checknil(co.referent.metadata["aufirst"]))) end
    #if (strpos($url, "{AUTHOR}")) { $url = str_replace('{AUTHOR#', $lrequest_array['author'], $url);} 
    if url.index("{ISBN}")!=nil: url = url.gsub("{ISBN}", URI.escape(checknil(co.referent.metadata["isbn"]))) end
    if url.index("{PAGES}")!=nil:  url = url.gsub("{PAGES}", URI.escape(checknil(co.referent.metadata["pages"]))) end
    if url.index("{PART}")!=nil: url = url.gsub("{PART}", URI.escape(checknil(co.referent.metadata["part"]))) end
    if url.index("{QUARTER}")!=nil: url = url.gsub( "{QUARTER}", URI.escape(checknil(co.referent.metadata["quarter"]))) end
    if url.index("{SEASON}")!=nil:  url = url.gsub("{SEASON}", URI.escape(checknil(co.referent.metadata["season"]))) end
    if url.index("{GENRE}")!=nil: url = url.gsub("{GENRE}", URI.escape(checknil(co.referent.metadata["genre"]))) end
    return url;
  end
  
  
  def self.CheckHoldings(cdate, sdate, edate)
    sdate = sdate.gsub(/[^0-9]/,"")
    edate = edate.gsub(/[^0-9]/,"")
    cdate = cdate.gsub(/[^0-9]/, "")
    
    #====================================
    # now I check to see if the item
    # is in the coverage load
    #====================================
    if sdate!="" && edate!=""
      if (cdate.to_i >= sdate.slice(0, cdate.length).to_i) && (cdate.to_i <= edate.slice(0, cdate.length).to_i)
        return true
      else
        return false
      end
    elsif sdate!=""
      if cdate.to_i >= sdate.slice(0, cdate.length).to_i
        return true
      else
        return false
      end
    elsif edate!=""
      if cdate.to_i <= edate.slice(0,cdate.length).to_i
        return true
      else
        return false
      end
    else
      return false
    end
  end
  
  
  def self.isnumeric(s)
    s = s.to_s
    return s.match(/^\d*$/)
  end
  
  def self.checknil(s)
    return "" if s==nil
    return s if s!=nil
  end
  
end
