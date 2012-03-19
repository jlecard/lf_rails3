class UpdateCommentsAddCommentRelevant < ActiveRecord::Migration
  def self.up
    add_column :comments, :count_comment_relevant, :integer, :default => 0
    add_column :comments, :count_comment_not_relevant, :integer, :default => 0
  end

  def self.down
    remove_column :comments, :count_comment_relevant
    remove_column :comments, :count_comment_not_relevant
  end
end