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

class Synonymes
  ######################################################################
  ## This class generates the synonyme file for SOLR
  ## and index the words for the function "see also"
  ##
  ## The variable "FILE_INPUT" is the path file csv which contains 4 columns :
  ## col 1 : id
  ## col 2 : words synonyms
  ## col 3 : words target
  ## col 4 : words for see also
  ## example row in csv file: id;car;ferrari;bmw @;@ porshe
  ## @;@ is séparator by default for define multivalues (SEPARATOR_MULTI_VALUES)
  ##
  ## in solr synonyms.txt
  ## car, ferrari
  ##
  ## in solr index :
  ## index "searcher" constains multivalues : ferrari car
  ## index "association" constains multivalues : bmw porshe
  ## 
  ######################################################################
  @IS_SYNONYM = false
  @IS_ASSOCIATION = false
  
  if ARGV.length==0
    @IS_SYNONYM = true
    @IS_ASSOCIATION = true
  else
    if ARGV[0].downcase == '-s'
      @IS_SYNONYM = true
    elsif ARGV[0].downcase == '-a'
      @IS_ASSOCIATION = true
    else
      puts "synopsys: [-s][-a]"
      puts "No argument : BOTH"
      puts "-s : only synonyms"
      puts "-a : only associations for see also"
      exit 1; 
    end
  end
  
  ######################################################################
  
  RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
  
  require 'rubygems'
  require 'yaml'
  require 'iconv'
  require 'solr'
  
  if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
  require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'
  
  ######################################################################
  yp = YAML::load_file(RAILS_ROOT + "/config/config.yml")
  FILE_INPUT = yp["SYNONYMS_FILE_INPUT"]
  puts "FILE_INPUT: #{FILE_INPUT}"
  SEPARATOR_CSV = yp["SYNONYMS_SEPARATOR_CSV"] # ";\""
  puts "SEPARATOR_CSV: #{SEPARATOR_CSV}"
  FILE_OUTPUT = yp["SYNONYMS_FILE_OUTPUT_SOLR"] #"/usr/lib/ruby/gems/1.8/gems/solr-ruby-0.0.7/solr/conf/synonyms.txt"
  puts "FILE_OUTPUT: #{FILE_OUTPUT}"
  SEPARATOR_MULTI_VALUES = yp["SYNONYMS_SEPARATOR_MULTI_VALUES"] #"@;@"
  puts "SEPARATOR_MULTI_VALUES: #{SEPARATOR_MULTI_VALUES}"
  SEPARATOR = ";"
  ######################################################################
  
  def self.parse(s)
    if !s.blank?
      return s.gsub(/[\",]/,"").gsub(/^ /,"")
    end
  end
  
  def self.split(s)
    if !s.blank?
      return s.split(SEPARATOR)
    else
      return []
    end
  end
  
  def self.normalize(word)
    return "" if word.blank?
    word = word.gsub("\"","")
    word = word.gsub(SEPARATOR_MULTI_VALUES, "|LF_DEL|")
    word = word.gsub(";", ",")
    word = word.gsub(",", "")
    word = word.gsub("|LF_DEL|", SEPARATOR)
	word = word.gsub("--","-")
    word = word.chomp(",")
    word = word.chomp("/")
    return word
  end
  
  @id = 0
  @tab = Array.new()
  def self.addAssociation(searcher, association) 
    @id += 1
    @tab.push({:id => "ass_#{@id}", :collection_id => "association", :collection_name => "association", :searcher => searcher, :association => association, :title => "", :keyword => ""}) 
    
    if @id%100==0
      # on index tous les 100 docs
      begin
        @index.add(@tab)
        @tab.clear
      rescue => e
        puts "error : #{e.message}"
      end
    end
  end
  
  ######################################################################
  
  _sTime = Time.now().to_f
  
  if @IS_ASSOCIATION == true
    begin
      @index = Solr::Connection.new(LIBRARYFIND_SOLR_HARVESTING_URL, {:timeout => CFG_LF_TIMEOUT_SOLR})
      
      @index.send(Solr::Request::Delete.new(:query => 'collection_id:("association")'))
      @index.send(Solr::Request::Commit.new)
    rescue => e
      puts "error : #{e.message}"
    end
  end
  
  if @IS_SYNONYM == true
    _f = File.new(FILE_OUTPUT,"w+")
    _f.chmod(0777)
  end
  
  cpt_rows = 0
  File.open(FILE_INPUT).each do |rec|
    
    begin
      
      if cpt_rows > 0
        
        _row =  Array.new
        cpt = 0    
        rec.split(SEPARATOR_CSV).each do |item|
          item.chomp!
          _row.insert(cpt,item)
          cpt += 1
        end
        
        if cpt == 4
          _id = _row[0]
          _retenu = normalize(_row[1])
          _rejete = normalize(_row[2])
          _association = normalize(_row[3])
          
          _a = split(_rejete)
          
          if @IS_SYNONYM == true
            if !_a.nil?
              _a.each do |b|
                _f.write("#{_retenu},#{parse(b)}\n")
              end
            end
          end
          
          if @IS_ASSOCIATION == true
        
            _tab = Array.new()
            split(_retenu).each do |el|
              _tab.push(el)
            end
            split(_rejete).each do |el2|
              _tab.push(el2)
            end
            addAssociation(_tab, _association)
          end
        
          
        else
          puts "error : bad format for item : #{_row[0]}"
        end
        
      end 
    rescue => e
      puts "error : #{e.message}"
    end
    cpt_rows += 1
  end
  
  if @IS_SYNONYM == true
    begin
      _f.close()
    rescue => e
      puts "error : #{e.message}"
    end
  end
  
  puts "Nb rows #{cpt_rows}"
  puts "Nb see also #{@id}"
  
  if @IS_ASSOCIATION == true
    begin
      if !@tab.empty?
        @index.add(@tab)
      end
      @index.send(Solr::Request::Commit.new)
    rescue => err
      puts "error : " + err.message.to_s
    end
  end
  puts "Finish - time: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s + " sec."
  
end