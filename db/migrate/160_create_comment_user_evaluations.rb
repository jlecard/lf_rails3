
class CreateCommentUserEvaluations < ActiveRecord::Migration
  def self.up
    create_table :comment_user_evaluations do |t|
      t.column :uuid,               :string,      :null => false
      t.column :comment_id,         :integer,     :null => false
      t.column :comment_relevance,  :integer,     :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :comment_user_evaluations
  end
end
