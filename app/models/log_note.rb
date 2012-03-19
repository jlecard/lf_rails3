class LogNote < ActiveRecord::Base

  def self.note_create(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "count(id) total"
    from_clause = "" 
    where_clause = "l.int_add = 1"  
    group_by_clause = ""
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.note_delete(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "count(id) total"
    from_clause = "" 
    where_clause = "l.int_add = 0"  
    group_by_clause = ""
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.note_create_by_notice(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "l.object_uid notice_id, count(id) total"
    from_clause = "" 
    where_clause = "l.int_add = 1 and l.object_type = #{ENUM_NOTICE}"  
    group_by_clause = "l.object_uid"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.note_delete_by_notice(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "l.object_uid notice_id, count(id) total"
    from_clause = "" 
    where_clause = "l.int_add = 0 and l.object_type = #{ENUM_NOTICE}"  
    group_by_clause = "l.object_uid"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  
  def self.note_create_by_liste(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "l.object_uid liste_id, count(id) total"
    from_clause = "" 
    where_clause = "l.int_add = 1 and l.object_type = #{ENUM_LIST}"  
    group_by_clause = "l.object_uid"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max)
  end
  
  def self.note_delete_by_liste(unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time",  page = 1, max = 50)
    select_clause = "l.object_uid liste_id, count(id) total"
    from_clause = "" 
    where_clause = "l.int_add = 0 and l.object_type = #{ENUM_LIST}"  
    group_by_clause = "l.object_uid"
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
    
    requete += " from log_notes l "
    
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
    
    res = LogNote.find_by_sql(requete)
    
    total = 0
    count = LogNote.find_by_sql("SELECT FOUND_ROWS() as total")
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