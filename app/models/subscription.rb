class Subscription < ActiveRecord::Base
  
  set_primary_keys :object_type, :object_uid, :uuid
  
  belongs_to :community_users, :foreign_key => :uuid
  
  
  after_create { |subscription| 
    # update sub_notices_count for user if subscription object is Notice
    cu = CommunityUsers.getCommunityUserByUuid(subscription.uuid)
    if(cu.nil?)
      raise(" No user with uuid : #{subscription.uuid} ")
    end
    cu = CommunityUsers.incrementSubscriptionsCount(cu, subscription.object_type, 1)
    
    # increment subscriptions_count for user
    ObjectsCount.incrementObjectsCount(ENUM_COMMUNITY_USER, subscription.uuid, ENUM_SUBSCRIPTION, 1)
    
    # increment subscriptions_count for object (Notice or List or Comment)
    ObjectsCount.incrementObjectsCount(subscription.object_type, subscription.object_uid, ENUM_SUBSCRIPTION, 1)
    
  }
  
  
  after_destroy { |subscription|
  begin 
    # update sub_notices_count for user if subscription object is Notice
    cu = CommunityUsers.find(:first, :conditions => " uuid = '#{subscription.uuid}' ")
    if(cu.nil?)
      raise(" No user with uuid : #{subscription.uuid} ")
    end
    cu = CommunityUsers.decrementSubscriptionsCount(cu, subscription.object_type, 1)
    
    # decrement subscriptions_count for user
    ObjectsCount.decrementObjectsCount(ENUM_COMMUNITY_USER, subscription.uuid, ENUM_SUBSCRIPTION, 1)   
    
    # decrement subscriptions_count for object (Notice or List or Comment)
    ObjectsCount.decrementObjectsCount(subscription.object_type, subscription.object_uid, ENUM_SUBSCRIPTION, 1)
    
  rescue => e
    logger.error("[Subscription][after_destroy] Error : " + e.message)
    raise e
  end
  }
  
  
  def self.getSubscriptionByObject(object_type, object_uid, uuid)
    sub = Subscription.find(:first, :conditions => "object_type = #{object_type} AND object_uid = '#{object_uid}' AND uuid = '#{uuid}'")
    return sub
  end
  
  def self.getSubscriptionByTypeObject(object_type, uuid, page, max, sort = SORT_DATE, direction = DIRECTION_UP)
    if object_type.blank? or uuid.blank?
      raise "error"
    end
    if page.blank?
      page = 1
    end
    if max.blank?
      max = 10
    end
    offset = (page - 1) * max
    order = "change_state_date ASC"
    return Subscription.find(:all, :conditions => "object_type = #{object_type} AND uuid = '#{uuid}'", :offset => offset, :limit => max, :order => order)
  end
  
  
  def self.getSubscriptionsByUser(uuid)
    subscriptions = Subscription.find(:all, :conditions => " uuid = '#{uuid}' ")
    return subscriptions
  end
  
  
  def self.saveSubscription(object_type, object_uid, uuid, mail_notification, state)
    sub = Subscription.new
    sub.object_type = object_type
    if(object_type == ENUM_NOTICE)
      doc_id , col_id = UtilFormat.parseIdDoc(object_uid)
      sub.object_uid = "#{doc_id};#{col_id}"
    else
      sub.object_uid = object_uid
    end
    sub.uuid = uuid
    sub.mail_notification = mail_notification
    sub.state = state
    sub.change_state_date = Time.new
    sub.subscription_date = Time.new
    sub.save
    return sub
  end
  
  
  def self.updateSubscription(sub, mail_notification, state)
    if(!mail_notification.nil? and mail_notification.to_i != sub.mail_notification)
      sub.mail_notification = mail_notification.to_i
    end
    if(!state.nil? and state.to_i != sub.state)
      sub.state = state.to_i
      sub.change_state_date= Time.new
    end
    sub.save
    return sub
  end
  
  # Delete subscription by object, object_uid and uuid
  def self.deleteSubscriptions(object_types, objects_ids, uuids)
    cnt_obj_id = 0
    objects_ids.each do |object_uid|
      Subscription.destroy_all(" object_type = #{object_types[cnt_obj_id]} and object_uid = '#{object_uid}' and uuid = '#{uuids[cnt_obj_id]}' ")
      cnt_obj_id += 1
    end
  end
  
  # getNoticesToCheckAvailability
  def self.getNoticesToCheckAvailability(collection_id)
    query = "SELECT DISTINCT(SUBSTRING_INDEX(REVERSE(object_uid),';',1)) AS collection_id FROM subscriptions "
    if(!state.nil?)
      query += " WHERE state = #{state.to_i} "
    end
    
    return Subscription.find_by_sql(query)
  end
  
  # getUsersByNotice
  def self.getUsersByNotice(doc_id)
    users = []
    subs = Subscription.find(:all, :conditions => " object_type = #{ENUM_NOTICE} and object_uid = '#{doc_id}' and state = #{SUBSCRIPTION_ACTIVE} AND mail_notification = #{MAIL_NOTIFICATION} ")
    subs.each do |sub|
      users << sub.uuid
    end
    return users
  end
  
  def self.updateCheckDate(check_date)
    Subscription.update_all(" check_date = '#{check_date}' " , " state = #{SUBSCRIPTION_ACTIVE} ")
  end
  
  def self.deleteAllAlerts(uuid)
    Subscription.destroy_all(" uuid = '#{uuid}' and object_type = #{ENUM_NOTICE} ")
  end
  
  def self.notifyAllByMail(uuid)
    Subscription.update_all(" mail_notification = #{MAIL_NOTIFICATION} " , " uuid = '#{uuid}' and object_type = #{ENUM_NOTICE} ")
  end
  
  
end