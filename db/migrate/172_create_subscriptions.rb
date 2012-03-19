class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table (:subscriptions, :primary_key => [:object,:object_id,:uuid]) do |t|
      t.string :object_id
      t.integer :object
      t.datetime :subscription_date
      t.datetime :modification_date
      t.string :uuid
      t.integer :mail_notification
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
