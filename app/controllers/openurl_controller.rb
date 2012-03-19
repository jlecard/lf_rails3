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
class OpenurlController < ApplicationController
  include ApplicationHelper
  layout 'libraryfind'
  
  def resolve
    co = OpenURL::ContextObject.new
    _openvals = Hash.new
    if params != nil
      _openvals['issn']=normalize(params['issn'])
      _openvals['isbn']=normalize(params['isbn'])
      _openvals['title']=normalize(params['title'])
      _openvals['atitle']=normalize(params['atitle'])
      _openvals['aulast']=normalize(params['author'])
      _openvals['volume'] = normalize(params['vol'])
      _openvals['num'] = normalize(params['num'])
      _openvals['issue'] = normalize(params['issue'])
      _openvals['date'] = UtilFormat.normalizeDate(params['date'])
      if normalize(params['doi'])!="" 
        _openvals['rft_id'] = "info:doi/" + checknil(params['doi'])
      else
        _openvals['rft_id'] = ""
      end
      _openvals['spage'] = normalize(params['page'])
      co.import_hash(_openvals)
    issn = checknil(co.referent.metadata["issn"]).gsub("-", "")
    essn = checknil(co.referent.metadata["essn"]).gsub("-", "")  
    isbn = checknil(co.referent.metadata["isbn"]).gsub("-", "")
    title = checknil(co.referent.metadata["title"])
    if title=='': title=checknil(co.referent.metadata["jtitle"]) end
    tdate = checknil(co.referent.metadata["date"])
    objRecord = nil
  
    #logger.debug("ready to search")
    if issn!="" && essn != "" && objRecord == nil
      objRecord = Coverage.find(:all, :conditions => "issn='#{issn}' OR eissn='#{essn}'")
    elsif essn != "" && objRecord == nil
      objRecord = Coverage.find(:all, :conditions => "eissn='#{essn}'")
    elsif issn != "" && objRecord == nil
      objRecord = Coverage.find(:all, :conditions => "issn='#{issn}'")
    elsif isbn != "" && objRecord == nil
      objRecord = Coverage.find(:all, :conditions => "isbn='#{isbn}'")
    else
      objRecord = Coverage.find(:all, :conditions => "LOWER(journal_title)='#{title}'")
    end      
    @url = nil
    if objRecord != nil  && objRecord.length() > 0
      @url = objRecord[0].url
    end
    if @url != nil && @url != ""
      redirect_to(@url)
    else
      @url = LIBRARYFIND_BASEURL
      redirect_to(@url)
    end
    else
        @url = LIBRARYFIND_BASEURL
        redirect_to(@url)    
    end



    
    #TODO: Faire la redirection vers le meilleur provider
  end
  
  private
  def normalize(_string)
    return "" if _string == nil
    _string = _string.gsub(/^\s*/,"") 
    _string = _string.gsub(/\s*$/,"")
    #Remove trailing punctuation
    _string = _string.gsub(/[.,;:-]*$/,"")
    #Remove html data 
    _string = _string.gsub(/<(\/|\s)*[^>]*>/, "")
    #_string = strip_tags(_string)
    #Remove trailing non word character
    _string = _string.gsub(/[\/ ]*$/,"")
    return _string
  end

  def checknil(_s) 
     return "" if _s == nil
     return _s.chomp()
  end
  
end