  # Atos Origin France - 
  # Tour Manhattan - La Défense (92)
  # roger.essoh@atosorigin.com
  
  
  class UsersTabsSearchesPreferences < ActiveRecord::Base  
    
    def self.saveUserTabSearchPreferences(uuid, search_tab, search_group, search_type)
      
      user_search_tab_pref = UsersTabsSearchesPreferences.find(:first, :conditions => " uuid = '#{uuid}' AND search_tab =#{search_tab}")
      if(user_search_tab_pref.nil?)
        user_search_tab_pref = UsersTabsSearchesPreferences.new;
      end
      user_search_tab_pref.uuid = uuid
      user_search_tab_pref.search_tab = search_tab
      user_search_tab_pref.search_group = search_group
      user_search_tab_pref.search_type = search_type
      user_search_tab_pref.save!
      return user_search_tab_pref
    end
    
    def self.getUserTabsSearches(uuid)
      return UsersTabsSearchesPreferences.find(:all, :conditions => " uuid = '#{uuid}' ")
    end
    
  end
