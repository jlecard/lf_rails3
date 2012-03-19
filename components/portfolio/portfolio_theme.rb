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
class PortfolioTheme
  def initialize(cnx, logger=nil, source=nil)
    restart
    @conn = cnx
    @logger = logger
    @source = source
    @select_libelle_time = 0
    @match_reference_time = 0
    @theme_name_concat_time = 0
    @array_themes_time = 0
    @records_count = 0
  end
  
  def restart
    @error = 0
    @indiceNotMatched = []
    @matched = 0
  end
  
  def errors
    return @error
  end
  
  def matched
    return @matched
  end
  
  def indices_no_match
    return @indiceNotMatched
  end
  
  def translateTheme(theme)
    @records_count += 1;
    _themes = []
    return "" if theme.blank?
    begin
      _label = nil
      # get label from cdu
      theme.split("@;@").each do |t|
        t = t.strip.gsub(/'/,"")
        
        query = "select libelle from dw_authorityindices where indice = '#{t}'"
        @logger.debug("translateTheme query = #{query}")
        r = @conn.select_one(query)
        _label = r['libelle'] if r
        @logger.debug("translateTheme _label = #{_label}")
        @logger.debug("translateTheme source = #{@source}")
        _r = ThemesReference.match_theme_references_with_ref_source(t, @source)
        @logger.debug("translateTheme _r = #{_r}")
        if !_r.nil? and !_r.empty?
          _r.each do |ref|
            _s = ref.name_theme()
            @logger.debug("translateTheme _s = #{_s}")    
            if !_label.nil? and !_s.nil?
              _s+= THEME_SEPARATOR + _label.capitalize
            end
            
            if !_s.nil? and !_themes.include?(_s)
              _themes << _s
            end
          end
        else
          if !@indiceNotMatched.include?(t)
            if @indiceNotMatched.size() < 1000
              @indiceNotMatched << t
            end
            @error += 1
          else
            @matched += 1
          end
        end
      end
    rescue => e
      if !@logger.nil?
        @logger.error("[translateTheme] error : #{e.message}")
        @logger.error("[translateTheme] trace : #{e.backtrace.join("\n")}")
      end
    end
    _retour = ""
    _themes.each do |v|
      _retour += ";#{v}"
    end
    return _retour.gsub(/^;/,"")
  end
  
end