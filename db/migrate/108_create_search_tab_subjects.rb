class CreateSearchTabSubjects < ActiveRecord::Migration
  def self.up
    create_table :search_tab_subjects do |t|
      t.integer :tab_id
      t.integer :parent_id
      t.string :label

      t.timestamps
    end
  end

  def self.down
    drop_table :search_tab_subjects
  end
end
