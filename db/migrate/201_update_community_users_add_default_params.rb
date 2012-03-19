class UpdateCommunityUsersAddDefaultParams < ActiveRecord::Migration
  
  def self.up
    users = CommunityUsers.find(:all)
    users.each do |u|
      user_pref = UsersPreferences.new
      user_pref.uuid = u.uuid;
      user_pref.all_profile_public = 0
      user_pref.description_public = 0
      user_pref.all_lists_public = 0
      user_pref.all_comments_public = 0
      user_pref.all_tags_public = 0
      user_pref.all_subscriptions_public = 0
      user_pref.save!
    end
  end
  
  def self.down
    users = CommunityUsers.find(:all)
    users.each do |u|
      userPref = UsersPreferences.find(:first, :conditions => ["uuid = ?", u.uuid])
      if !userPref.nil?
        userPref.destroy
      end
    end
  end
  
end