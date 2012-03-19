class UpdateNoticesAddUpdateDate < ActiveRecord::Migration
  def self.up
    add_column :notices, :update_date, :datetime
  end
  
  def self.down
    remove_column :notices, :update_date
  end
end