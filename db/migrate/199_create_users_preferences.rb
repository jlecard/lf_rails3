class CreateUsersPreferences < ActiveRecord::Migration
  def self.up
    create_table :users_preferences do |t|
      t.column :uuid,                             :string,      :null => false
      t.column :all_profile_public,               :integer,     :default => DEFAULT_PRIVACY_PUBLIC
      t.column :all_profile_followed,             :integer,     :default => DEFAULT_PRIVACY_PRIVATE
      t.column :description_public,               :integer,     :default => DEFAULT_PRIVACY_PUBLIC
      t.column :description_followed,             :integer,     :default => DEFAULT_PRIVACY_PRIVATE
      t.column :all_lists_public,                 :integer,     :default => DEFAULT_PRIVACY_PUBLIC
      t.column :all_lists_followed,               :integer,     :default => DEFAULT_PRIVACY_PRIVATE
      t.column :all_comments_public,              :integer,     :default => DEFAULT_PRIVACY_PUBLIC
      t.column :all_comments_followed,            :integer,     :default => DEFAULT_PRIVACY_PRIVATE
      t.column :all_tags_public,                  :integer,     :default => DEFAULT_PRIVACY_PUBLIC
      t.column :all_tags_followed,                :integer,     :default => DEFAULT_PRIVACY_PRIVATE
      t.column :all_subscriptions_public,         :integer,     :default => DEFAULT_PRIVACY_PUBLIC
      t.column :all_subscriptions_followed,       :integer,     :default => DEFAULT_PRIVACY_PRIVATE
      
      t.column :profile_subscriptions_subscribed, :integer,     :default => DEFAULT_NOT_SUBSCRIBED
      t.column :profile_subscriptions_mail_notif, :integer,     :default => DEFAULT_MAIL_NOT_NOTIFIED
      t.column :lists_subscriptions_subscribed,   :integer,     :default => DEFAULT_NOT_SUBSCRIBED
      t.column :lists_subscriptions_mail_notif,   :integer,     :default => DEFAULT_MAIL_NOT_NOTIFIED
      t.column :comments_responses_subscribed,    :integer,     :default => DEFAULT_NOT_SUBSCRIBED
      t.column :comments_responses_mail_notif,    :integer,     :default => DEFAULT_MAIL_NOT_NOTIFIED
      t.column :comments_lists_subscribed,        :integer,     :default => DEFAULT_NOT_SUBSCRIBED
      t.column :comments_lists_mail_notif,        :integer,     :default => DEFAULT_MAIL_NOT_NOTIFIED
      t.column :all_comments_subscribed,          :integer,     :default => DEFAULT_NOT_SUBSCRIBED
      t.column :all_comments_mail_notif,          :integer,     :default => DEFAULT_MAIL_NOT_NOTIFIED
      t.column :all_tags_subscribed,              :integer,     :default => DEFAULT_NOT_SUBSCRIBED
      t.column :all_tags_mail_notif,              :integer,     :default => DEFAULT_MAIL_NOT_NOTIFIED
      
      t.column :results_number,                   :integer,     :default => DEFAULT_RESULTS_NUMBER
      t.column :sort_value,                       :string,      :default => DEFAULT_SORT_VALUE
      
    end
  end
  
  def self.down
    drop_table :users_preferences
  end
end