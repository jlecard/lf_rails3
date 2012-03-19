require "digest"

class UpdateCommunityUsersAddMdfive < ActiveRecord::Migration
  
  def self.up
    add_column :community_users, :MD5, :string, :null => false
    
    users = CommunityUsers.find(:all)
    users.each do |u|
      u.MD5 = Digest::MD5.hexdigest(u.uuid);
      u.save!
    end
  end
  
  def self.down
    remove_column :community_users, :MD5
  end
  
end