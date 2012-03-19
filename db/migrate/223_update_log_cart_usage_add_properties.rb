class UpdateLogCartUsageAddProperties < ActiveRecord::Migration
  def self.up
    add_column :log_cart_usages, :profil, :string
    add_column :log_cart_usages, :first, :integer
  end
  
  def self.down
    remove_column :log_cart_usages, :profil
    remove_column :log_cart_usages, :first
  end
end