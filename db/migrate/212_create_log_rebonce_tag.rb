class CreateLogRebonceTag < ActiveRecord::Migration
  def self.up
    create_table :log_rebonce_tags do |t|
      t.integer :id_mode
      t.string :mode
      t.string :host
      t.string :word
      t.string :uuid
      t.timestamps
    end
  end

  def self.down
    drop_table :log_rebonce_tags
  end
end