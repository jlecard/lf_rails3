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

class ThemesImport
  
  ########################################################################################################
  # the file "theme.csv" describes the themes imported in the development database. 
  # This are the reference themes 
  # the main file : themes.csv
  # the file "mappingCDU" describes the patterns to match with the "cote" in the cdu
  # the file "mappingRG" describes the relations between the identifiants (apkid) and the reference themes
  # this script must be execute before harvesting
  ########################################################################################################
  
  RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
  
  require 'rubygems'
  require 'yaml'
  require 'iconv'
  
  if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
  require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'
  
  require ENV['LIBRARYFIND_HOME'] + 'app/models/themes_reference'
  require ENV['LIBRARYFIND_HOME'] + 'app/models/theme'
  
  def initialize
    ########################################################################################################
    ### configuration database
    ########################################################################################################
    @db = YAML::load_file(ENV['LIBRARYFIND_HOME'] + "config/database.yml")
    @dbtype = 'production'
    
    if defined? @db[@dbtype]["port"]
      ActiveRecord::Base.establish_connection(
                                              :adapter => @db[@dbtype]["adapter"],
      :host => @db[@dbtype]["host"],
      :username => @db[@dbtype]["username"],
      :password => @db[@dbtype]["password"],
      :database => @db[@dbtype]["database"]
      )
    else
      ActiveRecord::Base.establish_connection(
                                              :adapter => @db[@dbtype]["adapter"],
      :host => @db[@dbtype]["host"],
      :username => @db[@dbtype]["username"],
      :password => @db[@dbtype]["password"],
      :database => @db[@dbtype]["database"],
      :port => @db[@dbtype]["port"]
      )
    end
  end
  
  # Save theme in the database
  def addTheme(ref, label, level, sort, parent = nil)
    _theme = Theme.new()
    _theme.reference = ref
    _theme.label = Iconv.conv('UTF-8', 'ISO-8859-1', label)
    if sort.nil?
      sort = 1
    end
    _theme.sort = sort
    _theme.level = level
    _theme.parent = parent
    _theme.save!()
    return _theme
  end
  
  # Save theme reference in the database
  def addThemeReference(ref_src, ref_theme)
    if @hash.nil?
      @hash = Hash.new()
    end
    
    @hash[ref_src] = ref_theme
  end
  
  # Save theme reference exclusion in the database
  def addThemeExclusion(ref_src, ref_theme)
    if @hash_excl.nil?
      @hash_excl = Hash.new()
    end
    @hash_excl[ref_src] = ref_theme
  end
  
  # Method for normalize a string
  # delete the " at end string
  def normalize(s)
    return "" if s.nil?
    return s.gsub("\"","")
  end
  
  def generateThemeReference(file, source)
    @hash = nil
    @hash_excl = nil
    _source = source
    File.open(file).each do |rec|
      dataArray =  Array.new
      i = 0         
      rec.split(MEDIAVIEW_CSV_SEPARATOR).each do |element|
        dataArray.insert(i,element)
        i+= 1
      end
      taille = dataArray.length()
      ref = dataArray[0]
      
      cpt = 0
      dataArray.each do |elem|
        if cpt > 0 and !elem.blank?
          addThemeReference(elem,ref)
        end
        cpt += 1
      end
    end
    
    ThemesReference.create_references(@hash, _source)
  end
  
  ####################################################
  ### Delete all themes
  ####################################################
  def delete
    ThemesReference.delete_all
    Theme.delete_all
  end
  
  ####################################################
  # read the file themes.csv 
  ####################################################
  MEDIAVIEW_CSV_SEPARATOR = ";"
  
  THEME_FILE_SOURCE = ENV['LIBRARYFIND_HOME'] + "components/themes/themes.csv"
  THEME_CSV_SEPARATOR = ";"
  
  def import_theme
    escapeFirst = false
    
    File.open(THEME_FILE_SOURCE).each do |rec|
      dataArray =  Array.new
      i = 0         
      rec.split(THEME_CSV_SEPARATOR).each do |element|
        element.chomp!
        dataArray.insert(i,element)
        i+= 1
      end
      
      if escapeFirst and !dataArray[0].blank?
        parent = nil
        if dataArray[3] != "0"
          parent = dataArray[3]
        end
        rang = nil
        
        if (dataArray.size() > 4)
          rang = normalize(dataArray[4])
        end
        
        addTheme(normalize(dataArray[0]), normalize(dataArray[1]), normalize(dataArray[2]), rang, parent)
      end
      escapeFirst = true
    end
  end
  
  
  ####################################################
  # read the file mappingCDU.csv 
  ####################################################
  CDU_FILE_SOURCE = "mappingCDU.csv"
  CDU_CSV_SEPARATOR = ";"
  
  def import_cdu(source)
    @hash = nil
    _source = source
    File.open(CDU_FILE_SOURCE).each do |rec|
      
      dataArray =  Array.new
      i = 0         
      rec.split(CDU_CSV_SEPARATOR).each do |element|
        dataArray.insert(i,element)
        i+= 1
      end
      
      taille = dataArray.length()
      ref = dataArray[0]
      exclude = dataArray[2].chomp unless dataArray[2].nil?
      i = 0
      dataArray.each do |elem|
        if i > 0 and !elem.blank?
          tab = normalizeCdu(elem.chomp)
          exclude = normalizeCdu(exclude)
          tab.each do |item|
            #addThemeReference(item,ref)
          end
          exclude.each do |item|
            addThemeExclusion(item,ref)
          end
        end
        i += 1
      end
    end
    ThemesReference.create_references(@hash, _source, @hash_excl)
  end
  
  def normalizeCdu(chaine)
    # delete contant info
    _COTE_COMMENCE = "Cote commence par "
    _SANS_OBJET = "Sans objet"
    c = chaine.gsub(_COTE_COMMENCE, "").gsub(_SANS_OBJET, "")
    
    # Define separator
    _OU = "ou"
    _VIRGULE= ","
    c = c.gsub(_VIRGULE, _OU)
    tab = c.split(_OU)
    
    res = []
    tab.each do |elt|
      if !elt.blank?
        e = elt.strip
        # Space explicit name
        _ESPACE = "[espace]"
        e = e.gsub(_ESPACE, " ")
        res << e
      end
    end
    #    puts chaine + " => " + res.inspect
    return res
  end
  
  def normalizeExclusions(chaine)
    # delete contant info
    _COTE_COMMENCE = "Cote commence par "
    _SANS_OBJET = "Sans objet"
    c = chaine.gsub(_COTE_COMMENCE, "").gsub(_SANS_OBJET, "")
    
    # Define separator
    _OU = "ou"
    _VIRGULE= ","
    c = c.gsub(_VIRGULE, _OU)
    tab = c.split(_OU)
    
    res = []
    tab.each do |elt|
      if !elt.blank?
        e = elt.strip
        # Space explicit name
        _ESPACE = "[espace]"
        e = e.gsub(_ESPACE, " ")
        res << e
      end
    end
    #    puts chaine + " => " + res.inspect
    return res
  end
  ####################################################
  # Jeux de tests
  ####################################################
  #  addTheme("REF717", "Actualités, médias, presse", 1, 100)
  #  addTheme("REF718", "Articles de journaux et de magazines", 2, 100, "REF717")
  #  addTheme("REF723", "Sites de journaux et de magazines", 2, 110, "REF717")
  #  addTheme("REF817", "Documentation sur les médias et l’édition", 2, 120, "REF717")
  #  addTheme("REF822", "Arts", 1, 110)
  #  addTheme("REF823", "Généralités", 2, 100, "REF822")
  #  addTheme("REF833", "Art jusqu'au 19ème siècle", 2, 110, "REF822")
  
  # CDU
  #  addThemeReference("0(","REF718")
  #  addThemeReference("024","REF817")
  #  addThemeReference("03","REF817")
  #  addThemeReference("07","REF817")
  #  addThemeReference("09","REF817")
  #  addThemeReference("70\"11\"","REF833")
  #  
  #  _source = "cdu"
  #  
  #  _r = ThemesReference.create_references(@hash, _source)
  #  
  #  _r.each do |i|
  #    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  #  end
  #  
  #  # BDM_RG
  #  addThemeReference("717","REF717", true)
  #  addThemeReference("718","REF718")
  #  addThemeReference("723","REF723")
  #  addThemeReference("817","REF817")
  #  addThemeReference("822","REF822")
  #  addThemeReference("823","REF823")
  #  addThemeReference("833","REF833")
  #  _source = "bdmrg"
  #  
  #  _r = ThemesReference.create_references(@hash, _source)
  #  
  #  _r.each do |i|
  #    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  #  end
  #  
  #  
  #  # simulation indexation CDU porfolio
  #  puts "Simultation CDU"
  ##  _r = ThemesReference.match_theme_references_with_ref_source("024", "cdu")
  ##  _r.each do |i|
  ##    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  ##  end
  ##  
  ##  _r = ThemesReference.match_theme_references_with_ref_source("024.1", "cdu")
  ##  _r.each do |i|
  ##    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  ##  end
  #  
  #  _r = ThemesReference.match_theme_references_with_ref_source("70\"11\"", "cdu")
  #  _r.each do |i|
  #    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  #  end
  #  
  #  _r = ThemesReference.match_theme_references_with_ref_source("70\"11\" K", "cdu")
  #  _r.each do |i|
  #    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  #  end
  #  
  #   # simulation indexation CDU porfolio
  #  puts "Simultation rg"
  #  _r = ThemesReference.match_theme_references_with_ref_source("822", "bdmrg")
  #  _r.each do |i|
  #    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  #  end
  #  
  #  _r = ThemesReference.match_theme_references_with_ref_source("823", "bdmrg")
  #  _r.each do |i|
  #    puts "theme #{i.ref_source} : #{i.name_theme()} [source: #{i.source}]"
  #  end
  
  def run()
    delete
    import_theme
    
    ####################################################
    # read the files mediaview 
    # set Here schema name of the database
    ####################################################
    _path = ENV['LIBRARYFIND_HOME'] + "components/themes/mappingRG.csv"
    generateThemeReference(_path, "mdbrg")
    _path = ENV['LIBRARYFIND_HOME'] + "components/themes/mappingEAF.csv"
    generateThemeReference(_path, "mdbeaf")
    #generateThemeReference(_path, "autoformation")
    _path = ENV['LIBRARYFIND_HOME'] + "components/themes/mappingFilms.csv"
    generateThemeReference(_path, "mdbfilms")
    #generateThemeReference(_path, "films")
    _path = ENV['LIBRARYFIND_HOME'] + "components/themes/mappingSons.csv"
    generateThemeReference(_path, "mdbesv")
    
    import_cdu("portfoliodw")
    #import_cdu("portfolio")
  end
  
end

ti = ThemesImport.new
ti.import_cdu("portfoliodw")
