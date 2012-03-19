class CreateLogComment < ActiveRecord::Migration
  def self.up
    create_table :log_comments do |t|
      t.string :host
      t.string :object_uid
      t.string :object_type
      t.timestamps
    end
  end

  def self.down
    drop_table :log_comments
  end
end