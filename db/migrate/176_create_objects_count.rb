class CreateObjectsCount < ActiveRecord::Migration
  def self.up
    create_table :objects_counts do |t|
      t.integer :object
      t.string :object_id
      t.integer :lists_count, :default => 0
      t.integer :lists_count_public, :default => 0
      t.integer :comments_count, :default => 0
      t.integer :comments_count_public, :default => 0
      t.integer :subscriptions_count, :default => 0
      t.integer :notices_count, :default => 0
      t.integer :notices_count_public, :default => 0
      t.integer :tags_count, :default => 0
      t.integer :tags_count_public, :default => 0
    end
  end

  def self.down
    drop_table :objects_counts
  end
end