class UpdateLogSaveRequestAddProfil < ActiveRecord::Migration
  def self.up
    add_column :log_save_requests, :profil, :string
  end
  
  def self.down
    remove_column :log_save_requests, :profil
  end
end