class CreateLogRssUsages < ActiveRecord::Migration
  def self.up
    create_table :log_rss_usages do |t|
      t.string :rss_url
      
      t.timestamps
    end
  end

  def self.down
    drop_table :log_rss_usages
  end
end
