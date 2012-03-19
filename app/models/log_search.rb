class LogSearch < ActiveRecord::Base
  
  belongs_to :history_search, :foreign_key => :search_history_id
  belongs_to :search_tab_subject, :foreign_key => :search_tab_subject_id
  
  # unit = day/month/year
  # date = dd-mm-yyyy
  def self.total_request(unit = "day", date_from_str = nil, date_to_str = nil, tab = nil, order = "time",  page = 1, max = 50)
    
    select_clause = "h.tab_filter, count(h.tab_filter) total"
    from_clause = ""
    where_clause = ""
    group_by_clause = "h.tab_filter"
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max)
  end
  
  def self.couple_request(unit = "day", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50)
    
    select_clause = "h.tab_filter, h.search_group, s.label as search_type_label, count(h.search_group) total"
    from_clause = " , search_tab_filters s "
    group_by_clause = "h.search_group, s.label"
    where_clause = " and s.field_filter =  h.search_type"
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max)
  end
  
  def self.list_most_search_popular(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50)
    
    select_clause = "h.*, s.label as search_type_label, count(l.search_history_id) total"
    from_clause = " , search_tab_filters s "
    group_by_clause = "l.search_history_id"
    where_clause = "and h.search_tab_subject_id = -1 and l.context = 'search' and s.field_filter =  h.search_type "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max)
  end
  
  def self.search_theme(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50)
    
    select_clause = "h.search_tab_subject_id, count(l.search_history_id) total"
    from_clause = ""
    group_by_clause = "l.search_history_id"
    where_clause = "and h.search_tab_subject_id != -1 and l.context = 'theme' "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max)
  end
  
  def self.see_also(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50)
    
    select_clause = "h.tab_filter, count(h.tab_filter) total"
    from_clause = ""
    group_by_clause = "h.tab_filter"
    where_clause = "and l.context = 'seealso' "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max)
  end
  
  def self.rebonce(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50)
    
    select_clause = "h.tab_filter, count(h.tab_filter) total"
    from_clause = ""
    group_by_clause = "h.tab_filter"
    where_clause = "and l.context = 'rebonce' "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max)
  end
  
  def self.spell(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50)
    
    select_clause = "h.tab_filter, count(h.tab_filter) total"
    from_clause = ""
    group_by_clause = "h.tab_filter"
    where_clause = "and l.context = 'spell' "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max)
  end
  
  private
  def self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit = "day", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50)
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
    
    requete += " from history_searches h, log_searches l "
    
    if (!from_clause.blank?)
      requete += " #{from_clause} "
    end
    
    # CLAUSE CONDITION
    requete += " where h.id = l.search_history_id "
    
    date_from = UtilFormat.get_date(date_from_str)
    if (!date_from.nil?)
      requete += " and l.created_at > '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      requete += " and l.created_at < '#{date_to}' "
    end
    
    if (!tab.blank?)
      requete += " and h.tab_filter = '#{tab}' "
    end
    
    if (!where_clause.blank?)
      requete += " #{where_clause}"
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
    
    logger.fatal(requete)
    res = LogSearch.find_by_sql(requete)
    
    
    total = 0
    count = LogSearch.find_by_sql("SELECT FOUND_ROWS() as total")
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