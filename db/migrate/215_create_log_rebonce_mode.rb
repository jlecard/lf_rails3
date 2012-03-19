class CreateLogRebonceMode < ActiveRecord::Migration
  def self.up
    create_table :log_rebonce_modes do |t|
      t.string :mode
      t.string :host
      t.timestamps
    end
  end

  def self.down
    drop_table :log_rebonce_modes
  end
end