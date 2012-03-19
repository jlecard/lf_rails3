class UpdateSubscriptionsAddState < ActiveRecord::Migration
  def self.up
    rename_column   :subscriptions,   :modification_date, :check_date
    add_column      :subscriptions,   :send_mail_date,    :datetime
    add_column      :subscriptions,   :change_state_date, :datetime     
    add_column      :subscriptions,   :state,           :integer,           :default => 0
  end

  def self.down
    rename_column       :subscriptions,   :check_date, :modification_date
    remove_column       :subscriptions,   :send_mail_date
    remove_column       :subscriptions,   :change_state_date     
    remove_column       :subscriptions,   :state
  end
end