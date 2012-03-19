class UpdateNoticesAddDispo < ActiveRecord::Migration
  def self.up
    add_column :notices, :aviability_count, :integer, :default => 0
  end

  def self.down
    remove_column :notices, :aviability_count
  end
end