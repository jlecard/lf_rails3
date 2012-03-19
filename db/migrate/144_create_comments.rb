class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
          t.column :comment_date,        :datetime
          t.column :content,             :string,     :null => false
          t.column :uuid,                :string,     :null => false
          t.column :related_note,        :integer
          t.column :state,               :integer     
          t.column :state_manager,       :string
          t.column :state_date,          :datetime,   :null => false
          t.column :last_modified_date,  :datetime,   :null => false
          t.column :comment_relevance,   :integer
          t.column :alias_user,          :string
          t.column :object,              :integer    # 1 for Notice and 2 for List
          t.column :object_id,           :string

    end
  end

  def self.down
    drop_table :comments
  end
end
