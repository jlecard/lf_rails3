class UpdateListUserRecordsAddRank < ActiveRecord::Migration
  def self.up
    add_column :list_user_records, :rank, :integer, :default => 0
  end

  def self.down
    remove_column :list_user_records, :rank
  end
end