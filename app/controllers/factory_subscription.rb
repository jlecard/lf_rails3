class FactorySubscription < ActiveRecord::Base
  
  def self.createSubscription(subscription, notice = nil)
    
    if(subscription.nil?)
      raise " Subscription nil !!"
    end
    
    s = Struct::SubscriptionStruct.new();
    
    s.object_type = subscription.object_type
    s.object_uid = subscription.object_uid
    s.subscription_date = subscription.subscription_date
    s.mail_notification = subscription.mail_notification
    
    s.notice = notice
    return s
  end
end