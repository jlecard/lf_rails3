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

class ThemesReference < ActiveRecord::Base
  
  def initialize()
    super
    @name_theme = ""
  end
  
  def self.create_references(data, source, exclusions = nil)
    
    _tab = []
    
    return tab if data.nil?
    return tab if source.nil?
    
    data.each do |key, value| 
      
      if !key.nil? and !value.nil?
        _r = ThemesReference.new()
        _r.ref_source = key
        _r.ref_theme = value
        _r.source = source
        _r.save!()
        _tab << _r
      end
    end
    
    if !exclusions.nil?
      exclusions.each do |key, value| 
        if !key.nil? and !value.nil?
          _r = ThemesReference.new()
          _r.ref_source = key
          _r.exclusion = value
          _r.source = source
          _r.save!()
          _tab << _r
        end
      end
    end
    
    return _tab
  end
  
  def self.match_theme_references_with_ref_source(ref_source, source)
    # We need to query the references for which the source ref - ref_source (string) starts with what we have in db
    _tab = []
    request = "select * from themes_references where source = '#{source}'"
    request += " and substring('#{ref_source}',1, length(ref_source))=ref_source"
    _refs = find_by_sql(request)
    _refs.each do |reference|
      _tab << reference
    end
    
    return _tab
  end
  
  def name_theme()
    if @name_theme.blank?
      logger.debug("[name_theme] recherche du theme: #{self.ref_theme}")
      if !self.exclusion.blank? and !self.ref_theme.blank?
        _theme = Theme.find(:first, :conditions => ["reference = ? and id not ?", self.ref_theme, self.exclusion])
        logger.debug("[name_theme] : omission du thème d'id #{self.exclusion} -- #{_theme.name_to_root}") if !_theme.blank?
      elsif !self.ref_theme.blank?
        _theme = Theme.find(:first, :conditions => ["reference = ?", self.ref_theme])
      end
      
      if !_theme.nil?
        @name_theme = _theme.name_to_root
      end
    end
    logger.debug("[name_theme] #{@name_theme}")
    return @name_theme
  end
end