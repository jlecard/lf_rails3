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

require 'collection'
require 'htmlentities'

class UtilFormat
  
  def self.normalizeFerretKeyword(_string)
    return "" if _string == nil
    #the quote isn't escaped because it is actually useful in this case.
    _string = _string.gsub(/([\'\:\(\)\[\]\{\}\!\+\~\^\-\|\<\>\=\*\?\\])/, '\\\\\1')
    return _string
  end
  
  def self.normalizeSolrKeyword(_string)
    return "" if _string == nil
    _string.squeeze('-');
    # Escape characters: +-&&||!(){}[]^"~*?:\
    _string = _string.gsub(/([\'\:\(\)\[\]\{\}\!\+\~\^\-\|\<\>\=\*\?\\])/, '\\\\\1')
    # Managing double quotes whitin the query string
    if _string.index(/^\".*\"$/) != nil
      _string = _string.slice(1, _string.length() - 2)
      _string = '"' + _string.gsub(/([.^\"]*)\"([.^\"]*)/, '\1\2\\\"\3') + '"'
    else
      _string = _string.gsub(/([.^\"]*)\"([.^\"]*)/, '\1\2\\\"\3')
    end
    return _string
  end
  
  def self.MultiFieldsOrganize(_qtype, _qstring, _qoperator)
    if _qtype.length < _qstring.length
      ActiveRecord::Base.logger.error("[UtilFormat][MultifieldOrganize] qstring and qtype not the same lengths")
      return nil
    end
    if _qoperator.length < _qtype.length-1
      ActiveRecord::Base.logger.error("[UtilFormat][MultifieldOrganize] ERROR - qstring miss or too much elements")
      return nil
    end
    
    if _qtype.blank?
      return nil
    end
    i = 0
    query = "("
    
    while i < _qtype.length do
#      ActiveRecord::Base.logger.fatal("qString : #{_qstring[i].class}")
      if _qstring[i].is_a?(Array)
        
        query += "("
        cpt = 0
        _qstring[i].each do |v|
          
          value = UtilFormat.normalizeSolrKeyword(v)
          
          if !value.blank?
            query += " #{_qtype[i]}:(#{value})"
            
            if cpt < _qstring[i].length - 1
              query += " OR "
            end
            
          end
          cpt += 1
          
        end
        
        query += ")"
      else
        value = UtilFormat.normalizeSolrKeyword(_qstring[i])
        if !value.blank?
          query += " #{_qtype[i]}:(#{value})"
        end
      end
      
      if i < _qoperator.length && _qtype.length > _qoperator.length
        query += " " + _qoperator[i]
      end
      i += 1
    end
    query += " )"
    ActiveRecord::Base.logger.debug("[UtilFormat][Generate] query : #{query}")
    return query     
  end
  
  def self.normalizeDate(_string)
    
    return "" if _string.blank?
    
    begin
      out = ""
      _string = _string.gsub(/-/, "")
      arr = _string.split(';')
      arr.each do |item|
        item = item.chomp
        # logger.debug("Item: " + item + "\nLength: " + item.length.to_s)
        if item.length <= 10
          _string = _string.gsub(/[^0-9]/, "")
          
          yyyy = "-1"
          mm = "-1"
          dd = "-1"
          
          if _string.length >= 4
            yyyy = _string.slice(0,4)
          end
          
          if _string.length >= 6
            mm = _string.slice(4,2)
          end
          
          if _string.length >= 8 
            dd = _string.slice(6,2)
          end
          
          if yyyy.to_i > 0 and yyyy.to_i < 2500
            out = yyyy
            
            if mm.to_i > 0 and mm.to_i <= 12
              out = "#{out}-#{mm}"
              
              if dd.to_i > 0 and dd.to_i <= 31
                out = "#{out}-#{dd}"
              end
            end
          end
          
        end
      end
    rescue
    end
    return out
  end
  
  def self.normalize(_string)
    return _string.gsub(/[^a-z^A-Z^_^0-9^\)^\]^\[^"^;]$/,"").to_s.chomp  if _string != nil
    return ""
  end
  
  # Return params for id notice
  # call: idDoc, idColl, idSearch = UtilFormat.parseIdDoc(doc)
  def self.parseIdDoc(doc)
    idDoc = nil
    idColl = nil
    idSearch = nil
    if !doc.blank?
      tmp = doc.split(ID_SEPARATOR)
      if tmp.size() >= 2
        idDoc = tmp[0]
        idColl = tmp[1]
      end
      
      if tmp.size() == 3
        idSearch = tmp[2]
      end
    end
    col_id = Integer(idColl)
    
    if(!col_id.is_a?(Integer))
      raise("[UtilFormat][parseIdDoc] Invalid collection id : #{idColl} !!")
    end
    return idDoc, idColl, idSearch
  end
  
  def self.analyzeParams(_qtype,_qstring,_coll_list)
    cpt_type = 0
    while cpt_type < _qtype.length do
      if(_qtype[cpt_type] == 'document_type')
        document_type_cols = DocumentType.getDocumentTypesValues(_qstring[cpt_type],_coll_list)
#        ActiveRecord::Base.logger.fatal("analyzeParams : #{document_type_cols.inspect}")
        if !document_type_cols.nil? and !document_type_cols.empty?
          _qstring[cpt_type] = Array.new
          document_type_cols.each do |type|
            _qstring[cpt_type] << type.document_type_name
          end
        end
#        ActiveRecord::Base.logger.fatal("analyzeParams : #{_qstring[cpt_type].inspect}")
      end
      cpt_type += 1
    end
    return _qstring
  end
  
  def self.normalizeLang(lang)
    if lang == nil 
      return ""
    end
    case lang.downcase
      when "fr"
      return "Francais"
      when "fr_fr"
      return "Francais"
      when "en"
      return "Anglais"
      when "en_en"
      return "Anglais"
      when "en_us"
      return "Anglais"
      when "us"
      return "Anglais"
      when "us_us"
      return "Anglais"
      when "fre"
      return "Francais"
      when "de"
      return "Allemand"
      when "es"
      return "Espagnol"
      when "ja"
      return "Japonais"
      when "cn"
      return "Chinois"
    else
      return lang.capitalize
    end
  end
  
  def self.generateRequestSolr(_qtype, _qstring, _qoperator, filter_query, isParent, collection_id, collection_name, max, options)
    _qstring = UtilFormat.analyzeParams(_qtype,_qstring,collection_id)
    params = UtilFormat.MultiFieldsOrganize(_qtype, _qstring, _qoperator)
    raw_query_string = ""
    if isParent == 1
      raw_query_string = "+collection_id:(\"#{collection_id}\")"
    elsif !collection_name.blank?
      collection_name = collection_name.gsub("http_//", "")
      raw_query_string = "+collection_name:(\"#{collection_name}\")"
    end
    #ActiveRecord::Base.logger.debug("[UtilFormat] [generateRequestSolr1] => #{raw_query_string}")
    
    if !params.blank? and !params.eql?("( )")
      raw_query_string += " #{params}"
    end
    
    if filter_query.blank?
      filter_query = ""
    end
    #ActiveRecord::Base.logger.debug("[UtilFormat] [generateRequestSolr] filter_query => #{filter_query}")
    raw_query_string += "#{filter_query}"
    #ActiveRecord::Base.logger.debug("[UtilFormat] [generateRequestSolr2] => #{raw_query_string}")
    # Adding options
    if !options.nil?
      if !options["isbn"].nil? and options["isbn"].to_i == 1
        raw_query_string += " isbn:[* TO *] "
      end
      if !options["news"].nil? and options["news"].to_i == 1
        raw_query_string += " date_end_new:[NOW TO *]"
      end
      if !options["query"].nil? and !options["query"].blank?
        raw_query_string += " +#{options["query"].strip} "          
      end
    end
    
    opt = {}
    opt[:rows] = max
      
    if (!options.nil? and !options["sort"].blank?)
      opt[:sort] = [{options["sort"] => "desc"}]
     end
    ActiveRecord::Base.logger.info("[UtilFormat] [generateRequestSolr] => #{raw_query_string} opt: #{opt.inspect}")
    return raw_query_string, opt
  end
  
  def self.remove_accents (str)
    value = str.dup
    # accents = { 
      # ['á','à','â','ä','ã','Ã','Ä','Â','À'] => 'a',
      # ['é','è','ê','ë','Ë','É','È','Ê']     => 'e',
      # ['í','ì','î','ï','I','Î','Ì']         => 'i',
      # ['ó','ò','ô','ö','õ','Õ','Ö','Ô','Ò'] => 'o',
      # ['œ']                                 => 'oe',
      # ['ß']                                 => 'ss',
      # ['ú','ù','û','ü','U','Û','Ù']         => 'u',
      # ['ç']                                 => 'c'
    # };
    # accents.each do |ac,rep|
      # ac.each do |s|
        # value.gsub!(s, rep)
      # end
    # end
    return (value)
  end
  
  # Escape html characters
  def self.html_encode(string)
    coder = HTMLEntities.new
    return coder.encode(string, :basic, :named, :decimal)
  end
  
  # Unescape html characters
  def self.html_decode(string)
    coder = HTMLEntities.new
    return coder.decode(string) 
  end
  
  # format "dd-mm-yyyy"
  # retourne datetime
  # if minuit = set to 00:00:00
  # else set to 23:59:59
  def self.get_date(string, minuit = true, separator='/', format = "%Y-%m-%d %H:%M:%S")
    if (string.blank?)
      return nil
    end
    datetime = nil
    begin
      hour = "00"
      min = "00"
      sec = "00"
      if !minuit
        hour = "23"
        min = "59"
        sec = "59"
      end
      tab = string.split(separator)
      datetime = Time.mktime(tab[2], tab[1], tab[0], hour, min, sec)
      return datetime.strftime(format)
    rescue => e
      ActiveRecord::Base.logger.error("[UtilFormat] [get_date] => #{e.message} with date: #{string}")
    end
    
    return datetime
  end
end