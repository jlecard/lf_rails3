class CreateLogSaveNotice < ActiveRecord::Migration
  def self.up
    create_table :log_save_notice do |t|
      t.string :idDoc
      t.integer :saveIn
      t.string :host
      t.string :uuid, :default => nil
      t.timestamps
    end
  end

  def self.down
    drop_table :log_save_notice
  end
end
