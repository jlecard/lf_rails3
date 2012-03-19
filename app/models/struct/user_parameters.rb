class Struct::UserParameters < ActionWebService::Struct
  
  member :uuid, :string
  member :user_name, :string
  member :profile_description, :string
  
  member :all_profile_public,               :integer
  member :all_profile_followed,             :integer
  member :description_public,               :integer
  member :description_followed,             :integer
  member :all_lists_public,                 :integer
  member :all_lists_followed,               :integer
  member :all_comments_public,              :integer
  member :all_comments_followed,            :integer
  member :all_tags_public,                  :integer
  member :all_tags_followed,                :integer
  member :all_subscriptions_public,         :integer
  member :all_subscriptions_followed,       :integer
  
  member :profile_subscriptions_subscribed, :integer
  member :profile_subscriptions_mail_notif, :integer
  member :lists_subscriptions_subscribed,   :integer
  member :lists_subscriptions_mail_notif,   :integer
  member :comments_responses_subscribed,    :integer
  member :comments_responses_mail_notif,    :integer
  member :comments_lists_subscribed,        :integer
  member :comments_lists_mail_notif,        :integer
  member :all_comments_subscribed,          :integer
  member :all_comments_mail_notif,          :integer
  member :all_tags_subscribed,              :integer
  member :all_tags_mail_notif,              :integer
  
  member :results_number,                   :integer
  member :sort_value,                       :string
  
  member :searches_preferences, [Struct::UserSearchesPreferences]

  def initialize
    super
    self.uuid = ""
    self.user_name = ""
    self.profile_description = ""
    self.all_profile_public = ""
    self.all_profile_followed = ""
    self.description_public = ""
    self.description_followed = ""
    self.all_lists_public = ""
    self.all_lists_followed = ""
    self.all_comments_public = ""
    self.all_comments_followed = ""
    self.all_tags_public = ""
    self.all_tags_followed = ""
    self.all_subscriptions_public = ""
    self.all_subscriptions_followed = ""
    
    self.profile_subscriptions_subscribed = ""
    self.profile_subscriptions_mail_notif = ""
    self.lists_subscriptions_subscribed = ""
    self.lists_subscriptions_mail_notif = ""
    self.comments_responses_subscribed = ""
    self.comments_responses_mail_notif = ""
    self.comments_lists_subscribed = ""
    self.comments_lists_mail_notif = ""
    self.all_comments_subscribed = ""
    self.all_comments_mail_notif = ""
    self.all_tags_subscribed = ""
    self.all_tags_mail_notif = ""
    
    self.results_number = ""
    self.sort_value = ""    

    self.searches_preferences = []

  end

end
