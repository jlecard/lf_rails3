class UpdateNoticesAddListsCount < ActiveRecord::Migration
  def self.up
    add_column :notices, :lists_count, :integer, :default => 0
  end

  def self.down
    remove_column :notices, :lists_count
  end
end