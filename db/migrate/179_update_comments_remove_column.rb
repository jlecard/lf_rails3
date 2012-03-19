class UpdateCommentsRemoveColumn < ActiveRecord::Migration
  def self.up
    add_column :comments, :note_id, :integer, :default => 0
    add_column :comments, :like_count, :integer, :default => 0
    add_column :comments, :dont_like_count, :integer, :default => 0
    remove_column :comments, :comment_relevance
    add_column :comments, :comment_relevance, :integer, :default => 0
    remove_column :comments, :evaluation_count
    remove_column :comments, :last_modified_date
    remove_column :comments, :alias_user
  end

  def self.down
    remove_column :comments, :note_id
    remove_column :comments, :like_count
    remove_column :comments, :dont_like_count
    add_column :comments, :evaluation_count, :integer
    add_column :comments, :last_modified_date, :datetime
    add_column :comments, :alias_user, :string
  end
end