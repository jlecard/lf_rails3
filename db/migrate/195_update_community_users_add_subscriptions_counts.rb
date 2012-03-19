class UpdateCommunityUsersAddSubscriptionsCounts < ActiveRecord::Migration
  
  def self.up
    rename_column :community_users, :sub_notices_count, :alerts_availability_count
    add_column :community_users, :rss_feeds_count, :integer, :default => 0
    add_column :community_users, :searches_history_count, :integer, :default => 0
  end
  
  def self.down
    rename_column :community_users, :alerts_availability_count, :sub_notices_count
    remove_column :community_users, :rss_feeds_count
    remove_column :community_users, :searches_history_count    
  end
  
end