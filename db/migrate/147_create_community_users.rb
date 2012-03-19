class CreateCommunityUsers < ActiveRecord::Migration
  def self.up
    create_table :community_users do |t|
          t.column :uuid, :string, :null => false
          t.column :name, :string
    end
  end

  def self.down
    drop_table :community_users
  end
end