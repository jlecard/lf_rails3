class CreateLogRebonceUsages < ActiveRecord::Migration
  def self.up
    create_table :log_rebonce_usages do |t|
      t.string :query
      t.string :filter
      t.timestamps
    end
  end

  def self.down
    drop_table :log_rebonce_usages
  end
end
