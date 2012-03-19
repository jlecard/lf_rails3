class FactoryProfile < ActiveRecord::Base
  
  
  
  def self.createProfile(community_user, user_lists, user_tags,user_pref ,user = nil)
    if community_user.nil?
      return nil;
    end
    
    p = Struct::Profile.new();
    
    p.uuid = community_user.uuid
    p.name = community_user.name
    p.MD5 = community_user.MD5
    p.user_type = community_user.user_type
    
    oc = ObjectsCount.getObjectCountById(ENUM_COMMUNITY_USER, community_user.uuid)
    
    if (!user.nil?)
      p.lists_count = oc.lists_count
      p.notices_count = oc.notices_count
      p.comments_count = oc.comments_count
      p.tags_count = oc.tags_count
    else
      p.lists_count = oc.lists_count_public
      p.notices_count = oc.notices_count_public
      p.comments_count = oc.comments_count_public
      p.tags_count = oc.tags_count_public
    end
    

    
    p.subscriptions_count = oc.subscriptions_count
    p.rss_feeds_count = community_user.rss_feeds_count
    p.alerts_availability_count = community_user.alerts_availability_count
    p.searches_history_count = community_user.searches_history_count
    
    p.lists = user_lists
    p.tags = user_tags
    
    
    p.description_profile = community_user.description
    if !user_pref.nil?
      p.all_profile_public = user_pref.all_profile_public
      p.description_public = user_pref.description_public
      p.all_lists_public = user_pref.all_lists_public
      p.all_comments_public = user_pref.all_comments_public
      p.all_tags_public = user_pref.all_tags_public
      p.all_subscriptions_public = user_pref.all_subscriptions_public
    end
   
   
    
    return p
  end
  
end