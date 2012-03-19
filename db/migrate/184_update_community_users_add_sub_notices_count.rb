class UpdateCommunityUsersAddSubNoticesCount < ActiveRecord::Migration
  def self.up
      add_column :community_users, :sub_notices_count, :integer, :default => 0
  end

  def self.down
    remove_column :community_users, :sub_notices_count
  end
end