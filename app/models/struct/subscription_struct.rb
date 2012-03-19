

class Struct::SubscriptionStruct < ActionWebService::Struct
  
   member :object_type, :integer
   member :object_uid, :string
   member :title,     :string
   member :mail_notification, :integer
   member :subscription_date, :datetime
   member :notice, Struct::NoticeStruct
   
  def initialize
    super
    self.object_type = 0;
    self.object_uid = "";
    self.title = "";
    self.mail_notification = 0
    self.subscription_date = Time.new()
    self.notice = nil
  end
  
end