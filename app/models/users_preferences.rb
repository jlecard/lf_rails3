  # Atos Origin France - 
  # Tour Manhattan - La Défense (92)
  # roger.essoh@atosorigin.com
  
  
  class UsersPreferences < ActiveRecord::Base  
    
    # Method saveUserPrivacyPreferences
    def self.saveUserPrivacyPreferences(uuid, all_profile_public, all_profile_followed, 
                  description_public, description_followed, all_lists_public, all_lists_followed,
                  all_comments_public, all_comments_followed, all_tags_public, all_tags_followed, 
                  all_subscriptions_public, all_subscriptions_followed)
                  
      user_pref = UsersPreferences.find(:first, :conditions => " uuid = '#{uuid}' ");
      if(user_pref.nil?)
        user_pref = UsersPreferences.new;
      end
      user_pref.uuid = uuid;
      user_pref.all_profile_public = all_profile_public;
      user_pref.all_profile_followed = all_profile_followed
      user_pref.description_public = description_public
      user_pref.description_followed = description_followed
      user_pref.all_lists_public = all_lists_public
      user_pref.all_lists_followed = all_lists_followed
      user_pref.all_comments_public = all_comments_public
      user_pref.all_comments_followed = all_comments_followed
      user_pref.all_tags_public = all_tags_public
      user_pref.all_tags_followed = all_tags_followed
      user_pref.all_subscriptions_public = all_subscriptions_public
      user_pref.all_subscriptions_followed = all_subscriptions_followed
      
      user_pref.save;
      return user_pref;
    end
    
    
    def self.getUserPrivacyPreferences(uuid)
      return UsersPreferences.find(:first, :conditions => " uuid = '#{uuid}' ")
    end
    
    def self.deleteUserPreferences(uuid)
      UsersPreferences.destroy_all(" uuid = '#{uuid}' ")
    end
    
    def self.saveUserMonitoringPreferences(uuid, profile_subscriptions_subscribed, profile_subscriptions_mail_notif, 
                  lists_subscriptions_subscribed, lists_subscriptions_mail_notif, comments_responses_subscribed, comments_responses_mail_notif,
                  comments_lists_subscribed, comments_lists_mail_notif, all_comments_subscribed, all_comments_mail_notif, 
                  all_tags_subscribed, all_tags_mail_notif)
                  
      user_pref = UsersPreferences.find(:first, :conditions => " uuid = '#{uuid}' ");
      if(user_pref.nil?)
        user_pref = UsersPreferences.new;
      end
      
      user_pref.uuid = uuid;
      user_pref.profile_subscriptions_subscribed = profile_subscriptions_subscribed
      user_pref.profile_subscriptions_mail_notif = profile_subscriptions_mail_notif
      user_pref.lists_subscriptions_subscribed = lists_subscriptions_subscribed
      user_pref.lists_subscriptions_mail_notif = lists_subscriptions_mail_notif
      user_pref.comments_responses_subscribed = comments_responses_subscribed
      user_pref.comments_responses_mail_notif = comments_responses_mail_notif
      user_pref.comments_lists_subscribed = comments_lists_subscribed
      user_pref.comments_lists_mail_notif = comments_lists_mail_notif
      user_pref.all_comments_subscribed = all_comments_subscribed
      user_pref.all_comments_mail_notif = all_comments_mail_notif
      user_pref.all_tags_subscribed = all_tags_subscribed
      user_pref.all_tags_mail_notif = all_tags_mail_notif
      
      user_pref.save;
      return user_pref;
    end
    
    
    def self.saveUserDisplayPreferences(uuid, results_number, sort_value)
                  
      user_pref = UsersPreferences.find(:first, :conditions => " uuid = '#{uuid}' ");
      if(user_pref.nil?)
        user_pref = UsersPreferences.new;
      end
      
      user_pref.uuid = uuid;
      if(!results_number.nil?)
        user_pref.results_number = results_number
      end
      if(!sort_value.nil?)
        user_pref.sort_value = sort_value
      end
      user_pref.save;
      return user_pref;
    end   
    
    def self.getUserParameters(uuid)
      return UsersPreferences.find(:first, :conditions => " uuid = '#{uuid}' ")
    end
    
    def self.getUserPrivacyParameters(uuid)
      return UsersPreferences.find_by_sql("SELECT uuid, all_profile_public, description_public, all_lists_public, all_comments_public, all_tags_public, all_subscriptions_public, results_number, sort_value FROM users_preferences WHERE uuid = '#{uuid}' ")
    end
    
    def self.updateAll(uuid, paramsObject)
      user_pref = UsersPreferences.find(:first, :conditions => " uuid = '#{uuid}' ");
      if(user_pref.nil?)
        user_pref = UsersPreferences.new;
      end
      user_pref.uuid = uuid;
      user_pref.all_profile_public = paramsObject['all_profile_public']
      user_pref.description_public = paramsObject['description_public']
      if (user_pref.all_lists_public != paramsObject['all_lists_public'])
        List.updateAllUserListsState(uuid, paramsObject['all_lists_public'])
      end
      user_pref.all_lists_public = paramsObject['all_lists_public']
      if (user_pref.all_comments_public != paramsObject['all_comments_public'])
        Comment.updateAllUserCommentsState(uuid, paramsObject['all_comments_public'])
      end
      user_pref.all_comments_public = paramsObject['all_comments_public']
      if (user_pref.all_tags_public != paramsObject['all_tags_public'])
        Tag.updateAllUserTagsState(uuid, paramsObject['all_tags_public'])
      end
      user_pref.all_tags_public = paramsObject['all_tags_public']
      user_pref.all_subscriptions_public = paramsObject['all_subscriptions_public']
      
      user_pref.results_number = paramsObject['results_number']
      user_pref.sort_value = paramsObject['sort_value']
      
      user_pref.save
    end
    
  end
