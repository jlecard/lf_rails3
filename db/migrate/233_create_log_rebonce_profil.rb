class CreateLogRebonceProfil < ActiveRecord::Migration
  def self.up
    create_table :log_rebonce_profils do |t|
      t.string :profil
      t.string :host
      t.string :uuid_md5
      t.timestamps
    end
  end
  
  def self.down
    drop_table :log_rebonce_profils
  end
end