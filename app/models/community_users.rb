require "digest"

class CommunityUsers < ActiveRecord::Base
  
  set_primary_key :uuid

  has_many :subscriptions,            :foreign_key => :uuid,      :dependent => :destroy
  has_many :comments_public,          :foreign_key => :uuid,      :dependent => :destroy,  :conditions => " state = #{COMMENT_PUBLIC}",  :class_name => "Comment"
  has_many :comments_all,             :foreign_key => :uuid,      :dependent => :destroy,  :class_name => "Comment"
  has_many :lists_public,             :foreign_key => :uuid,      :dependent => :destroy,  :conditions => " state = #{LIST_PUBLIC}",     :class_name => "List"
  has_many :lists_all,                :foreign_key => :uuid,      :dependent => :destroy,  :class_name => "List"
  has_many :objects_tags_public,      :foreign_key => :uuid,      :dependent => :destroy,  :conditions => " state = #{TAG_PUBLIC}",      :class_name => "ObjectsTag"
  has_many :objects_tags_all,         :foreign_key => :uuid,      :dependent => :destroy,  :class_name => "ObjectsTag"
  has_many :notes,                    :foreign_key => :uuid,      :dependent => :destroy
  has_many :comments_alerts,          :foreign_key => :uuid,      :dependent => :destroy
  has_one  :objects_count,            :foreign_key => :object_uid, :dependent => :destroy,  :conditions => " object_type = #{ENUM_COMMUNITY_USER} "
  has_many :comment_user_evaluations, :foreign_key => :uuid,      :dependent => :destroy 
  
  
  after_create { |user| 
    # create count for user
    ObjectsCount.createCount(ENUM_COMMUNITY_USER, user.uuid) 
  }

  # Method addCommunityUsers
  def self.addCommunityUsers(uuid,name,user_type)
    u = CommunityUsers.new;
    u.uuid = uuid;
    u.name = name;
    u.MD5 = Digest::MD5.hexdigest(uuid);
    # initialisation des préférences par defaut.
    user_pref = UsersPreferences.new
    user_pref.uuid = uuid;
    user_pref.all_profile_public = 0
    user_pref.description_public = 0
    user_pref.all_lists_public = 0
    user_pref.all_comments_public = 0
    user_pref.all_tags_public = 0
    user_pref.all_subscriptions_public = 0
    user_pref.save
    if(!user_type.nil?)
      u.user_type = user_type
    end
    u.save;
    return u;
    
  end
  
  # Method deleteCommunityUsers
  def self.deleteCommunityUsers(uuid)
    CommunityUsers.destroy(uuid);  
  end
  
  
  # Method getCommunityUserByUuid
  #   returns : community user with uuid
  def self.getCommunityUserByUuid(uuid)
    cu = CommunityUsers.find(:first, :conditions => " uuid = '#{uuid}' ")
    return cu;
  end
  
  # Method getCommunityUserByIdentifier
  #   returns : uuid
  def self.getCommunityUserByIdentifier(identifier)
    cu = CommunityUsers.find(:first, :conditions => " MD5 = '#{identifier}' ")
    return cu;
  end
  
  # Method : updateProfileDescription
  def self.updateProfileDescription(community_user, description)
    community_user.description = description
    community_user.save
    return community_user
  end
  
  def self.incrementSubscriptionsCount(community_user, object_type, objects_count=1)
    case object_type
      when ENUM_NOTICE
        community_user.alerts_availability_count += objects_count
      when ENUM_RSS_FEED
        community_user.rss_feeds_count += objects_count
      when ENUM_SEARCH_HISTORY
        community_user.searches_history_count += objects_count
    end
    community_user.save!
    return community_user
  end
 
  def self.decrementSubscriptionsCount(community_user, object_type, objects_count=1)
    case object_type
      when ENUM_NOTICE
        community_user.alerts_availability_count -= objects_count
        if(community_user.alerts_availability_count < 0)
          community_user.alerts_availability_count = 0
        end
      when ENUM_RSS_FEED
        community_user.rss_feeds_count -= objects_count
        if(community_user.rss_feeds_count < 0)
          community_user.rss_feeds_count = 0
        end
      when ENUM_SEARCH_HISTORY
        community_user.searches_history_count -= objects_count
        if(community_user.searches_history_count < 0)
          community_user.searches_history_count = 0
        end
    end
    community_user.save!
    return community_user
  end  
  
  def self.updateUserInfos(community_user, user_name, profile_description, desc)
    if !user_name.blank?
      community_user.name = user_name
    end
    if !profile_description.blank?
      community_user.description = desc
    end
    community_user.save!
    return community_user
  end
  
end