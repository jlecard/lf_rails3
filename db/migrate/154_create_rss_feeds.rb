class CreateRssFeeds < ActiveRecord::Migration
  def self.up
    create_table :rss_feeds do |t|
      t.timestamps
      t.column :name,                   :string, :null => false
      t.column :full_name,              :string, :null => false
      t.column :primary_document_type,  :integer
      t.column :new_docs,               :integer
      t.column :isbn_issn_nullable,     :integer
      t.column :collection_group,       :integer
      t.column :solr_request,           :string, :null => false
      t.column :update_periodicity,     :integer
      t.column :url,                    :string

    end
    
  end
  
  def self.down
    drop_table :rss_feeds
  end
end