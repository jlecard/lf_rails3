  class HistorySearch < ActiveRecord::Base
    
    has_many :users_history_search, :foreign_key => :id_history_search, :dependent => :destroy
    
    def self.parseSearchWord(txt)
      if !txt.blank?
        return txt.gsub("'","")
      end
      return ""
    end
    
    def self.getHistorySearch(tab_filter, search_input,search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, search_tab_subject_id)
      logger.debug("[HistorySearch][getSearch] Checking search : tab_filter = #{tab_filter} search_input = #{search_input} and search_group = #{search_group} and search_type = #{search_type} and search_operator1 = #{search_operator1} and search_input2 = #{search_input2} and search_type2 = #{search_type2} and search_operator2 = #{search_operator2} and search_input3 = #{search_input3} and search_type3 = #{search_type3} and tab_filter = #{tab_filter}")
      conditions = "tab_filter = '#{tab_filter}' and search_input = '#{self.parseSearchWord(search_input)}' and search_group = '#{search_group}' and search_type = '#{search_type}' "
      if(!search_input2.nil?)
        conditions += " and search_operator1 = '#{search_operator1}' and search_input2 = '#{self.parseSearchWord(search_input2)}' and search_type2 = '#{search_type2}' "
      else
        conditions += " and search_input2 is NULL "
      end
      if(!search_input3.nil?)
        conditions += " and search_operator2 = '#{search_operator2}' and search_input3 = '#{self.parseSearchWord(search_input3)}' and search_type3 = '#{search_type3}' "
      else
        conditions += " and search_input3 is NULL "
      end      
      
      conditions += " and search_tab_subject_id = #{search_tab_subject_id}"
      
      return HistorySearch.find(:first, :conditions => conditions)
    end
    
    def self.saveHistorySearch(tab_filter, search_input,search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, search_tab_subject_id)
      rh = HistorySearch.new()
      rh.tab_filter = tab_filter
      rh.search_input = self.parseSearchWord(search_input)
      rh.search_group = search_group
      rh.search_type = search_type
      rh.search_operator1 = search_operator1
      rh.search_input2 = self.parseSearchWord(search_input2)
      rh.search_type2 = search_type2
      rh.search_operator2 = search_operator2
      rh.search_input3 = self.parseSearchWord(search_input3)
      rh.search_type3 = search_type3
      rh.search_tab_subject_id = search_tab_subject_id
      rh.save
      return rh
    end
    
    def self.deleteHistorySearch(history_search_ids)
      ids = history_search_ids.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      HistorySearch.destroy_all(" id IN #{ids}" )
    end
    
    def self.getHistorySearch(id_history_search)
      return HistorySearch.find(:first, :conditions => " id='#{id_history_search}' ")
    end
    
    def self.findHistorySearch(tab_filter, search_input,search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, search_tab_subject_id)
      return HistorySearch.find(:first, :conditions => " tab_filter = '#{tab_filter}' and search_input = '#{self.parseSearchWord(search_input)}' and search_group = '#{search_group}' and search_type = '#{search_type}' and search_operator1 = '#{search_operator1}' and search_input2 = '#{self.parseSearchWord(search_input2)}' and search_type2  = '#{search_type2}' and search_operator2 = '#{search_operator2}' and search_input3  = '#{self.parseSearchWord(search_input3)}' and search_type3 = '#{search_type3}' and search_tab_subject_id = #{search_tab_subject_id} ")
    end
    
    def self.getUserSearchesHistory(uuid, max = 20, page = 1, sort = SORT_DATE, direction = DESC)
      query = "SELECT uhs.id, uhs.save_date, uhs.results_count, uhs.id_history_search, "
      query += "hs.search_input, hs.search_group, hs.search_type, hs.tab_filter, hs.search_operator1, "
      query += "hs.search_input2, hs.search_type2, hs.search_operator2, hs.search_input3, hs.search_type3, hs.search_tab_subject_id, "
      query += "cg.full_name as collection_group_name FROM users_history_searches uhs, history_searches hs, "
      query += "collection_groups cg WHERE hs.id = uhs.id_history_search and cg.id = SUBSTR(hs.search_group,2) "
      query += "and uhs.uuid = '#{uuid}'"
      
      sort_sql = ""
      if SORT_DATE == sort
        sort_sql = "order by uhs.save_date "
      end
      
      direction_sql = ""
      if DIRECTION_UP == direction
        direction_sql = "ASC"
      elsif DIRECTION_DOWN == direction
        direction_sql = "DESC"
      end
      
      query += sort_sql + direction_sql
      
      if (page > 0)
        offset = (page - 1) * max
        limit = max
        query += " limit #{offset}, #{limit}"
      end
      
      return HistorySearch.find_by_sql(query)
    end
    
  end