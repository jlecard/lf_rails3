  # Atos Origin France - 
  # Tour Manhattan - La Défense (92)
  # roger.essoh@atosorigin.com
  
  
  class UsersHistorySearch < ActiveRecord::Base
  
    after_create { |history_search|
      begin        
        if !history_search.nil?
          community_user = CommunityUsers.getCommunityUserByUuid(history_search.uuid)
          if(community_user.nil?)
            raise("No community user with uuid #{history_search.uuid} !!")
          end
          oc = ObjectsCount.incrementObjectsCount(ENUM_COMMUNITY_USER, community_user.uuid, ENUM_SUBSCRIPTION, 1)
          community_user = CommunityUsers.incrementSubscriptionsCount(community_user, ENUM_SEARCH_HISTORY, 1)
        end
      rescue => e
        logger.error("[UsersHistorySearch][after_create] Error : " + e.message)
        raise e
      end
    }

    after_destroy { |history_search|
      begin
        if !history_search.nil?
          community_user = CommunityUsers.getCommunityUserByUuid(history_search.uuid)
          if(community_user.nil?)
            raise("No community user with uuid #{history_search.uuid} !!")
          end
          oc = ObjectsCount.decrementObjectsCount(ENUM_COMMUNITY_USER, community_user.uuid, ENUM_SUBSCRIPTION, 1)
          community_user = CommunityUsers.decrementSubscriptionsCount(community_user, ENUM_SEARCH_HISTORY, 1)
        end
      rescue => e
        logger.error("[UsersHistorySearch][after_destroy] Error : " + e.message)
        raise e
      end
    }    
    
    # Method saveUserSearch
    def self.saveUserHistorySearch(uuid, results_count, id_history_search)
      urh = UsersHistorySearch.getUserHistorySearch(uuid, id_history_search)
      if (urh.nil?)
        urh = UsersHistorySearch.new;
      end
      urh.id_history_search = id_history_search
      urh.results_count = results_count
      urh.uuid = uuid
      urh.save_date = Time::new
      urh.save;
      return urh;
    end
    
    def self.getUserHistorySearch(uuid, id_history_search)
      return UsersHistorySearch.find(:first, :conditions => " uuid = '#{uuid}' and id_history_search = #{id_history_search} ")
    end
    
    def self.deleteUserHistorySearches(user_searches_ids, uuid)
      ids = user_searches_ids.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      UsersHistorySearch.destroy_all(" uuid = '#{uuid}' and id IN #{ids} ")
    end
    
  end
