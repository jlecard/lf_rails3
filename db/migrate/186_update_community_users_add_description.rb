class UpdateCommunityUsersAddDescription < ActiveRecord::Migration
  def self.up
    add_column :community_users, :description, :string
  end

  def self.down
    remove_column :community_users, :description
  end
end