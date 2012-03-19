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
class LogConsult < ActiveRecord::Base
   
  def self.get_material_type()
    return LogConsult.find_by_sql("select distinct(material_type) from log_consults order by material_type ASC")
  end
  
  def self.topConsulted(unit = "", date_from_str = nil, date_to_str = nil, profil = nil, order = "total",  page = 1, max = 10, type = nil)
    select_clause = "idDoc, title, collection_id, c.alt_name, material_type, count(idDoc) total"
    from_clause = " , collections c" 
    where_clause = "action='consult' and context='notice' and c.id=l.collection_id" 
    if (!type.nil? and !type.blank?)
      where_clause += " and material_type = '#{type}'"
    end
    group_by_clause = "idDoc, collection_id"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.consult_notice_by_collection(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "c.alt_name collection_name, count(l.id) total"
    from_clause = ",collections c" 
    where_clause = "c.id = l.collection_id and l.action='consult' and l.context='notice'" 
    group_by_clause = "l.collection_id"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.consult_notice(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "count(id) total"
    from_clause = "" 
    where_clause = "action='consult' and context='notice'" 
    group_by_clause = "profil"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.print_notice(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "count(id) total"
    from_clause = "" 
    where_clause = "action='print'" 
    group_by_clause = "profil"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.email_notice(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "count(id) total"
    from_clause = "" 
    where_clause = "action='email'" 
    group_by_clause = "profil"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.pdf_notice(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "count(id) total"
    from_clause = "" 
    where_clause = "action='pdf'" 
    group_by_clause = "profil"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.export_notice(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "context, count(id) total"
    from_clause = "" 
    where_clause = "action='export'" 
    group_by_clause = "context"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.topExport(unit = "", date_from_str = nil, date_to_str = nil, profil = nil, order = "total",  page = 1, max = 10)
    select_clause = "idDoc, title, collection_id, material_type, count(idDoc) total, c.alt_name"
    from_clause = " , collections c" 
    where_clause = "action='export' and c.id = l.collection_id " 
    group_by_clause = "idDoc, collection_id"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  private
  def self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time", page = 1, max = 50)
    # CLAUSE SELECT
    requete = "select SQL_CALC_FOUND_ROWS #{select_clause}"
    
    case unit
      when "month"
      requete += ", month(created_at) month, year(created_at) year "
      when "year"
      requete += ", year(created_at) year "
      when "day"
      requete += ", day(created_at) day, month(created_at) month, year(created_at) year "
    end
    
    requete += " from log_consults l "
    
    if (!from_clause.blank?)
      requete += " #{from_clause} "
    end
    
    # CLAUSE CONDITION
    requete += " where #{where_clause}"
    
    date_from = UtilFormat.get_date(date_from_str)
    if (!date_from.nil?)
      requete += " and l.created_at > '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      requete += " and l.created_at < '#{date_to}' "
    end
    
    if (!profil.blank?)
      requete += " and profil = '#{profil}' "
    end
    
    # CLAUSE GROUP BY
    if (!group_by_clause.blank? or (unit == "month" or unit=="year" or unit=="day"))
      requete += " group by #{group_by_clause}"
      if (!group_by_clause.blank? and (unit == "month" or unit=="year" or unit=="day"))
        requete += ","
      end
    end
    
    case unit
      when "month"
      requete += " month, year"
      when "year"
      requete += " year"
      when "day"
      requete += " day, month, year"
    end
    
    # CLAUSE ORDER
    requete += " order by "
    
    if (order == "time")
      case unit
        when "month"
        requete += "year desc, month desc"
        when "year"
        requete += "year desc"
        when "day"
        requete += "year desc, month desc, day desc"
      else
        requete += "total DESC"
      end
    else
      requete += "total DESC"
    end
    
    # PAGINATE
    if page > 0:
      offset = (page.to_i-1) * max.to_i
      requete += " limit #{offset}, #{max}"
    end
    
    res = LogConsult.find_by_sql(requete)
    
    total = 0
    count = LogConsult.find_by_sql("SELECT FOUND_ROWS() as total")
    if (!count.nil? and !count.empty?)
      total = count[0].total
    end
    
    tab = []
    res.each do |v|
      hash = Hash.new()
      v.attributes.each do |k, v|
        hash[k] = v
      end
      tab << hash
    end
    
    return {:result => tab, :count => total, :page => page, :max => max}
  end
  
end
