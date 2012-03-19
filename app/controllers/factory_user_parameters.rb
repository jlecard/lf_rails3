class FactoryUserParameters < ActiveRecord::Base
  
  def self.createFactoryUserParameters(community_user, user_preferences, user_tab_search_preferences = [])
    if community_user.nil?
      return nil;
    end
    
    p = Struct::UserParameters.new();
    if !user_preferences.nil?
      p.uuid = community_user.uuid
      p.user_name = community_user.name
      p.profile_description = community_user.description
      p.all_profile_public = user_preferences.all_profile_public
      p.all_profile_followed = user_preferences.all_profile_followed
      p.description_public = user_preferences.description_public
      p.description_followed = user_preferences.description_followed
      p.all_lists_public = user_preferences.all_lists_public
      p.all_lists_followed = user_preferences.all_lists_followed
      p.all_comments_public = user_preferences.all_comments_public
      p.all_comments_followed = user_preferences.all_comments_followed
      p.all_tags_public = user_preferences.all_tags_public
      p.all_tags_followed = user_preferences.all_tags_followed
      p.all_subscriptions_public = user_preferences.all_subscriptions_public
      p.all_subscriptions_followed = user_preferences.all_subscriptions_followed
      
      p.profile_subscriptions_subscribed = user_preferences.profile_subscriptions_subscribed
      p.profile_subscriptions_mail_notif = user_preferences.profile_subscriptions_mail_notif
      p.lists_subscriptions_subscribed = user_preferences.lists_subscriptions_subscribed
      p.lists_subscriptions_mail_notif = user_preferences.lists_subscriptions_mail_notif
      p.comments_responses_subscribed = user_preferences.comments_responses_subscribed
      p.comments_responses_mail_notif = user_preferences.comments_responses_mail_notif
      p.comments_lists_subscribed = user_preferences.comments_lists_subscribed
      p.comments_lists_mail_notif = user_preferences.comments_lists_mail_notif
      p.all_comments_subscribed = user_preferences.all_comments_subscribed
      p.all_comments_mail_notif = user_preferences.all_comments_mail_notif
      p.all_tags_subscribed = user_preferences.all_tags_subscribed
      p.all_tags_mail_notif = user_preferences.all_tags_mail_notif
    
      p.results_number = user_preferences.results_number
      p.sort_value = user_preferences.sort_value
    end
  
    p.searches_preferences = user_tab_search_preferences
    
    return p
  end
  
  def self.createFactoryUserPrivacyParameters(community_user, user_preferences, user_tab_search_preferences = [])
    if community_user.nil?
      return nil;
    end
    
    p = Struct::UserParameters.new();
    if !user_preferences.nil? and !user_preferences[0].nil?
      p.uuid = community_user.uuid
      p.user_name = community_user.name
      p.profile_description = community_user.description
      p.all_profile_public = user_preferences[0].all_profile_public
      p.description_public = user_preferences[0].description_public
      p.all_lists_public = user_preferences[0].all_lists_public
      p.all_comments_public = user_preferences[0].all_comments_public
      p.all_tags_public = user_preferences[0].all_tags_public
      p.all_subscriptions_public = user_preferences[0].all_subscriptions_public
          
      p.results_number = user_preferences[0].results_number
      p.sort_value = user_preferences[0].sort_value
    end
  
    p.searches_preferences = user_tab_search_preferences
    
    return p
  end
  
end