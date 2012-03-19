class UpdateLogSaveNoticeAddProperties < ActiveRecord::Migration
  def self.up
    
    drop_table :log_save_notice
    
    create_table :log_save_notices do |t|
      t.string :idDoc
      t.string :saveIn
      t.string :host
      t.string :profil
      t.timestamps
    end
    
    add_index :log_save_notices, :saveIn
  end
  
  def self.down
    
    remove_index :log_save_notices, :saveIn
    
    drop_table :log_save_notices
    
    create_table :log_save_notice do |t|
      t.string :idDoc
      t.integer :saveIn
      t.string :host
      t.string :uuid, :default => nil
      
      t.timestamps
    end
  end
end