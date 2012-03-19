# LibraryFind - Quality find done better.
# Copyright (C) 2010 Atos Origin


class CreateNotices < ActiveRecord::Migration
  def self.up
    create_table :notices, :primary_key => [:doc_identifier, :doc_collection_id] do |t|
      t.column :doc_identifier,       :string,   :null => false,   :limit => 255
      t.column :doc_collection_id,    :integer,  :null => false
      t.column :created_at, :timestamp
      t.column :dc_title, :string
      t.column :dc_author, :string
      t.column :dc_type, :string
      t.column :notes_count,          :integer,  :default => 0
      t.column :notes_avg,            :float,    :default => 0.0
      t.column :comments_count,       :integer,  :default => 0
      t.column :isbn, :string
      t.column :ptitle, :string
    end
  end

  def self.down
    drop_table :notices
  end
end
