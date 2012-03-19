class Struct::Profile < ActionWebService::Struct
  
  member :uuid, :string
  member :name, :string
  member :MD5,  :string
  member :user_type, :string  
  member :description_profile, :string
  
  member :notices_count, :integer
  member :lists_count, :integer
  member :comments_count, :integer


  member :tags_count, :integer
  member :subscriptions_count, :integer
  member :rss_feeds_count, :integer
  member :searches_history_count, :integer
  member :alerts_availability_count, :integer
  
  # profile public 0 si public 1 si pas public
  member :all_profile_public, :integer
  # description_public  0 si public 1 si pas public
  member :description_public, :integer
  # :all_lists_public  0 si public 1 si pas public
  member :all_lists_public, :integer
  # all_comments_public 0 si public 1 si pas public
  member :all_comments_public, :integer
  # all_tags_public 0 si public 1 si pas public
  member :all_tags_public, :integer
  # all_subscriptions_public 0 si public 1 si pas public
  member :all_subscriptions_public, :integer
  
  member :lists, [Struct::ListUser]   # Simple lists

  member :tags, [Struct::TagStruct]         # Simple tags
  
  
  def initialize
    super
    self.uuid = ""
    self.MD5 = ""
    self.name = ""
    self.user_type = ""  
    self.description_profile = ""

    self.subscriptions_count = 0
    
    self.notices_count = 0
    self.lists_count = 0
    self.comments_count = 0
    self.tags_count = 0
    self.rss_feeds_count = 0
    self.searches_history_count = 0
    self.alerts_availability_count = 0    
    self.lists = []
    self.tags = []
    # sur l'ecran c'est ne pas rendre public
    # donc non public = 1
    self.all_profile_public = 1
    self.description_public = 1
    self.all_lists_public = 1
    self.all_comments_public = 1
    self.all_tags_public = 1
    self.all_subscriptions_public = 1
  end
end
