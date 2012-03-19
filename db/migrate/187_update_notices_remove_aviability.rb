class UpdateNoticesRemoveAviability < ActiveRecord::Migration
  def self.up
    remove_column :notices, :aviability_count
  end

  def self.down
    add_column :notices, :aviability_count, :integer
  end
end