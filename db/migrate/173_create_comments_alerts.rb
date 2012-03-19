class CreateCommentsAlerts < ActiveRecord::Migration
  def self.up
    create_table(:comments_alerts, :primary_key => [:comment_id,:uuid]) do |t|
      t.integer :comment_id, :null => false
      t.string :uuid, :null => false
      t.text :message
      t.datetime :send_date
    end
  end

  def self.down
    drop_table :comments_alerts
  end
end
