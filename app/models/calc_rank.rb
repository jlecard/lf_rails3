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

require 'yaml'

class CalcRank
 
  yp = YAML::load_file(RAILS_ROOT + "/config/ranking.yml")
  #Title Value
  TITLE_PERFECT_MATCH = yp['TITLE_PERFECT_MATCH']
  TITLE_PARTIAL_MATCH = yp['TITLE_PARTIAL_MATCH']
  TITLE_PARTIAL_MATCH_OFFSET_1 = yp['TITLE_PARTIAL_MATCH_OFFSET_1']
  TITLE_PARTIAL_MATCH_OFFSET_SUP = yp['TITLE_PARTIAL_MATCH_OFFSET_SUP']
  
  # Creator value
  CREATOR_PERFECT_MATCH = yp['CREATOR_PERFECT_MATCH']
  CREATOR_PARTIAL_MATCH = yp['CREATOR_PARTIAL_MATCH']
  CREATOR_PARTIAL_MATCH_OFFSET_1 = yp['CREATOR_PARTIAL_MATCH_OFFSET_1']
  CREATOR_PARTIAL_MATCH_OFFSET_SUP = yp['TITLE_PARTIAL_MATCH_OFFSET_SUP']
  
  # Subject value
  SUBJECT_PERFECT_MATCH = yp['SUBJECT_PERFECT_MATCH']
  SUBJECT_PARTIAL_MATCH_OFFSET_1 = yp['SUBJECT_PARTIAL_MATCH_OFFSET_1']
  SUBJECT_PARTIAL_MATCH_OFFSET_SUP = yp['SUBJECT_PARTIAL_MATCH_OFFSET_SUP']
  
  # Theme value
  THEME_PERFECT_MATCH = yp['THEME_PERFECT_MATCH']
  THEME_PARTIAL_MATCH = yp['THEME_PARTIAL_MATCH']
  
  # Indice value
  INDICE_PERFECT_MATCH = yp['INDICE_PERFECT_MATCH']
  INDICE_PARTIAL_MATCH = yp['INDICE_PARTIAL_MATCH']
  INDICE_PARTIAL_MATCH_OFFSET_1 = yp['INDICE_PARTIAL_MATCH_OFFSET_1']
  INDICE_PARTIAL_MATCH_OFFSET_SUP = yp['INDICE_PARTIAL_MATCH_OFFSET_SUP']
  
  def calc_rank(_rec, _keyword)
    _trank = 0
    _keyword = strip_ex(_keyword, "/^\W+$/",'')
    _keyword = _keyword.strip.downcase
    _t = Array.new()
    _lsubject = ""
    
    if _rec['subject'] != nil
      _lsubject = _rec['subject'].downcase
    end
    
    if _rec['special'] != nil
      _trank = _trank + 100 
    end
    
    _trank = _trank + (30-_rec['pos'].to_i)
    if _trank < 0
      _trank = 0
    end
    
    if _rec['atitle'] != nil
      if _rec['atitle']!=""
        _rec['title'] = _rec['atitle']
      end
    end
    _rec['title'] = strip_ex(_rec['title'],'/\W+$/','').downcase
    if _rec['title']!=nil
      if _keyword == _rec['title']
        _trank = _trank + TITLE_PERFECT_MATCH
      elsif _rec['title'].index(_keyword) != nil and _rec['title'].index(_keyword) < 5 
        _trank = _trank + TITLE_PARTIAL_MATCH
      end
    end
    
    if _rec['creator']!=nil
      if _keyword == _rec['creator'].downcase
        _trank = _trank + CREATOR_PERFECT_MATCH
      elsif _rec['creator'].downcase.index(_keyword) != nil
        _trank = _trank + CREATOR_PARTIAL_MATCH
      end
    else
      _trank = _trank - 20
    end
    
    if _lsubject == _keyword
      _trank = _trank + SUBJECT_PERFECT_MATCH
    end
    
    if _lsubject == ""
      _trank = _trank - 10
    end
    
    _t = _keyword.split(' ')
    _last = _t.length-1
    
    _z = _lsubject.index(_keyword)
    if _z != nil
      if _z <= 1
        _trank = _trank + SUBJECT_PARTIAL_MATCH_OFFSET_1
      else
        _trank = _trank + SUBJECT_PARTIAL_MATCH_OFFSET_SUP
      end
    else
      for _x in 0.._last
        _t[_x] = strip_ex(_t[_x], "/\W+$/",'')
        if _t[_x].strip.size>0
          if is_stop(_t[_x])!=true
            if _lsubject.downcase.index(_t[_x])
              if _x==0 
                _trank = _trank + 25
              else 
                _trank = _trank + 20
              end
            end
          end
        end
      end
    end
    
    if _rec['creator']!=nil
      _z = _rec['creator'].downcase.index(_keyword)
      if _z != nil
        if _z <=1
          _trank = _trank + CREATOR_PARTIAL_MATCH_OFFSET_1
        else
          _trank = _trank + CREATOR_PARTIAL_MATCH_OFFSET_SUP
        end
      else
        for _x in 0.._last
          _t[_x] = strip_ex(_t[_x], "/\W+$/",'')
          if _t[_x].strip.size>0
            if is_stop(_t[_x])!=true
              if _rec['creator'].downcase.index(_t[_x])
                if _x==0 
                  _trank = _trank + 25
                else 
                  _trank = _trank + 20
                end
              end
            end
          end
        end
      end
    end
    
    if _rec['title']!=nil
      _z = _rec['title'].index(_keyword)
      if _z != nil
        if _z <= 1
          _trank = _trank + TITLE_PARTIAL_MATCH_OFFSET_1
        else
          _trank = _trank + TITLE_PARTIAL_MATCH_OFFSET_SUP
        end
      end
    end
    
    if _rec['rec']!=nil
      if _rec['rec'].downcase.index(_keyword)
        _trank = _trank + (25 * string_count(_rec['rec'], _keyword))
      end
    end
    
    for _x in 0.._last
      _t[_x] = strip_ex(_t[_x],  "/\W+$/",'' )
      if _t[_x].strip.size>0
        if is_stop(_t[_x])!=true
          if _rec['title']!=nil
            if _rec['title'].index(_t[_x])
              if _x==0  
                _trank = _trank + 50
              else  
                _trank = _trank + 25
              end
            end
          end
          if _rec['rec']!=nil
            _trank = _trank + (0.25 * string_count(_rec['rec'], _t[_x]))
          end
        end
      end
    end
    
    if defined?(_rec['pref'])
      if _rec['pref'] != nil
        #_rec['url'] = _rec['url'].gsub(".", "\.")
        #_rec['url'] = _rec['url'].gsub("/", "\/")
        #if _rec['url'].index(/#{_rec['pref']}/) != nil
        if _rec['url'].index(_rec['pref']) != nil
          _trank = _trank + 50000
        end
      end
    end
    
    if defined?(_rec['theme'])
      if (_rec['theme'] != nil)
        _z = _rec['theme'].split(';');
        _keyword.strip;
        _z.each do |val|
          val = val.strip;
          if (val.downcase == _keyword.downcase)
            _trank = _trank + THEME_PERFECT_MATCH
          elsif val.index(_keyword) != nil and val.index(_keyword) < 5 
            _trank = _trank + THEME_PARTIAL_MATCH
          end
        end
      end
    end
    # calcul de pertinence prenant en compte l'indice
    _rec['indice'] = strip_ex(_rec['indice'],'/\W+$/','').downcase
   
    if _rec['indice']!=nil
      if _keyword == _rec['indice']
        _trank = _trank + INDICE_PERFECT_MATCH
      elsif _rec['indice'].index(_keyword) != nil and _rec['indice'].index(_keyword) < 5 
        _trank = _trank + INDICE_PARTIAL_MATCH
      end
      _z = _rec['indice'].index(_keyword)
      if _z != nil
        if _z <= 1
          _trank = _trank + INDICE_PARTIAL_MATCH_OFFSET_1
        else
          _trank = _trank + INDICE_PARTIAL_MATCH_OFFSET_SUP
        end
      end
    end
    # calcul de pertinence prenant en compte le type de document
    _rec['material_type'] = strip_ex(_rec['material_type'],'/\W+$/','').downcase
    if _rec['material_type']!=nil
      for _x in 0.._last
        _t[_x] = strip_ex(_t[_x], "/\W+$/",'')
        if _t[_x].strip.size>0
          if _rec['material_type'].downcase.index(_t[_x])
            if _x==0 
              _trank = _trank + 25
            else 
              _trank = _trank + 20
            end
          end
        end
      end
    end
    
    return _trank.to_s
  end
  
  

  def string_count(_haystack, _needle)
    _x = 1
    _pos = -1
    while _x==nil
      _x = _haystack.index(_x,_needle)
      _pos = _x if _x!=nil 
    end
    return _pos
  end

  def is_stop(_s)
    return false
  end

  def strip_ex(_string, _pat, _rep)
    return "" if _string == nil
    _string = _string.gsub(/\W+$/,_rep)
    _string = _string.gsub(/^\W+/,_rep)
    return _string
  end
end
  

