class FactorySearchesParameters < ActiveRecord::Base
  
  def self.createSearchesParameters(uts)
    
    s = Struct::UserSearchesPreferences.new();
    
    s.search_tab = uts.search_tab
    s.search_group = uts.search_group
    s.search_type = uts.search_type
        
    return s
  end
  
end