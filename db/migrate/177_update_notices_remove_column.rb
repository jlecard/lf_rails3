class UpdateNoticesRemoveColumn < ActiveRecord::Migration
  def self.up
    remove_column :notices, :comments_count
    remove_column :notices, :lists_count
  end

  def self.down
    add_column :notices, :comments_count, :integer, :default => 0
    add_column :notices, :lists_count, :integer, :default => 0
  end
end