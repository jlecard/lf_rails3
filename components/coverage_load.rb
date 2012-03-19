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

require 'rubygems'
require "mysql"
require 'net/http'
require 'uri'
require 'yaml'
require '../config/environment.rb'

delimiter = "|"

logger = ActiveRecord::Base.logger

def trim(s)
  if s == nil: return "" end
  return s.gsub(/^"+/, "").gsub(/"+$/, "")
end 

def checknil(s)
  if s == nil: return "" end
  return s
end

def isnumeric(s)
  if s.to_s.index(/[^0-9]/) != nil: return false
  else return true
  end

end

def cFormat(s)
if isnumeric(s.to_s) == true
  if s.to_i < 10: s = "0" + s.to_s end
  if s == "0": s = "" end
else
  tmp = s.to_s
  if isnumeric(tmp.slice(tmp.length-3, 3))==true
      tmp = tmp.slice(tmp.length - 3, 3).to_s
  elsif tmp.index("year ago") != nil || tmp.index("years ago") != nil
     t = Date.today().year - tmp.slice(1, tmp.index(" ")).to_i
     m = Date.today().month.to_s
     if m.to_i < 10: m = "0" + m.to_s end
     d = "01"
     tmp = t.to_s + m.to_s + d.to_s
  elsif tmp.index("month ago") != nil || tmp.index("months ago") != nil
     m = Date.today().month.to_i - ((tmp.slice(1, tmp.index(" ")).to_i) -1)
     if m == 0
       m = 12
       y = Date.today().year.to_i - 1
     elsif m < 0
       m = 12 + m
       y = Date.today().year.to_i - 1
     else
       y = Date.today().year.to_i
     end 
     tmp  = y.to_s + m.to_s
  else
    tmp = ""
  end
  s = tmp
end

return s

end

def normalize(s) 
  s = s.to_s
  if s.index("/") != nil
     tmp = s.split("/")
     if tmp.length == 3: s = tmp[2].to_s + cFormat(tmp[0]) + cFormat(tmp[1]) 
     else s = tmp[1].to_s + cFormat(tmp[0])
     end
  else
    s = cFormat(s)
  end

  return s
end

db = YAML::load_file("../config/database.yml")

if ARGV.length < 2
  logger.error("Usage: ruby coverage_load.rb [environment] [coveragefilepath] \n")
  exit
end

dbtype  = ARGV[0]
coverage_file = ARGV[1]

case PARSER_TYPE
  when 'libxml'
    require 'xml/libxml'
  when 'rexml'
    require 'rexml/document'
  else
    require 'rexml/document'
end


dbh = Mysql.real_connect(db[dbtype]["host"], db[dbtype]["username"], db[dbtype]["password"], db[dbtype]["database"])

#=======================================
#Setup the hash storing coverage data
#=======================================
line_index = {:journal_title => nil, :issn => nil, :eissn => nil, :isbn => nil, :start_date => nil, :end_date => nil, :provider => nil, :url => nil}

query = "";

#=======================================
# Read the coverage file
#=======================================
handle  = File.new(coverage_file, "r")
if handle == nil
   logger.info(coverage_file + " cannot be openned.")
   exit
end

coverage_header = handle.gets.strip
if coverage_header.index(delimiter) == nil: delimiter = "\t" end
tmparr = coverage_header.split(delimiter)

x = 0
tmparr.each do |a|
  case a.downcase
  when 'journal title': line_index['journal_title'] = x
  when 'issn': line_index['issn'] = x
  when 'eissn': line_index['eissn'] = x
  when 'isbn': line_index['isbn'] = x
  when 'start date': line_index['start_date'] = x
  when 'start_date': line_index['start_date'] = x
  when 'end date': line_index['end_date'] = x
  when 'end_date': line_index['end_date'] = x
  when 'provider': line_index['provider'] = x
  when 'resource': line_index['provider'] = x
  when 'url': line_index['url'] = x
  #else line_index[a] = nil
  end
  x = x+1
end

#================================
# setup vars
#================================
journal_title = ""
issn = ""
eissn = ""
isbn = ""
start_date = ""
end_date = ""
provider = ""
url = ""
mydate = Date.today().to_s.gsub("-", "")

query = "truncate table coverages"
dbh.query(query)
query = "optimize table coverages"
dbh.query(query)

while (line = handle.gets) 
  line = line.strip
  if delimiter != '|': line.gsub("|", "%124") end
  tmparr = line.split(delimiter)
  if line_index['journal_title']!=nil: journal_title = dbh.quote(trim(tmparr[line_index['journal_title'].to_i].to_s)) end
  if line_index['issn']!=nil: issn = dbh.quote(trim(tmparr[line_index['issn'].to_i].to_s.gsub("-", ""))) end
  if line_index['eissn']!=nil: eissn = dbh.quote(trim(tmparr[line_index['eissn'].to_i].to_s.gsub("-", ""))) end
  if line_index['isbn']!=nil: isbn = dbh.quote(trim(tmparr[line_index['isbn'].to_i].to_s.gsub("-", ""))) end
  if line_index['start_date']!=nil: start_date = dbh.quote(trim(normalize(tmparr[line_index['start_date'].to_i].to_s))) end
  if line_index['end_date']!=nil: end_date = dbh.quote(trim(normalize(tmparr[line_index['end_date'].to_i].to_s)))  end
  if line_index['provider']!=nil: provider = dbh.quote(trim(tmparr[line_index['provider'].to_i].to_s)) end
  if line_index['url']!=nil: url = dbh.quote(trim(tmparr[line_index['url'].to_i].to_s)) end
 
  query = "INSERT INTO coverages (journal_title, issn, eissn, isbn, start_date, end_date, provider, url, mod_date) values ('" + journal_title + "','" + issn + "','" + eissn + "','" + isbn + "','" + start_date + "','" + end_date + "','" + provider + "','" + url + "'," + mydate + ")"
  dbh.query(query)

  journal_title = ""
  isbn = ""
  issn = ""
  eissn = ""
  provider = ""
  start_date = ""
  end_date = ""
  url = ""
  
end 

dbh.commit()

logger.info("Finished processing")

