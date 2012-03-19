class UpdateCommunityUsers < ActiveRecord::Migration
  def self.up
    drop_table :community_users
    create_table (:community_users, :primary_key => [:uuid]) do |t|
      t.column :uuid, :string, :null => false
      t.column :name, :string
      t.column :user_type, :string, :default => "default_user"
    end
  end

  def self.down
    drop_table :community_users
    create_table :community_users do |t|
      t.column :uuid, :string, :null => false
      t.column :name, :string
    end
  end
end