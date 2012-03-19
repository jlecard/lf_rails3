class UpdateComments < ActiveRecord::Migration
  def self.up
    remove_column :comments, :count_comment_relevant
    remove_column :comments, :count_comment_not_relevant
    remove_column :comments, :related_note
    add_column :comments, :title, :string
    add_column :comments, :evaluation_count, :integer, :default => 0
    add_column :comments, :parent_id, :integer, :default => nil
  end

  def self.down
    add_column :comments, :related_note, :integer
    add_column :comments, :count_comment_relevant, :integer, :default => 0
    add_column :comments, :count_comment_not_relevant, :integer, :default => 0
    remove_column :comments, :evaluation_count
    remove_column :comments, :title
    remove_column :comments, :parent_id
  end
end