class CreateLogTag < ActiveRecord::Migration
  def self.up
    create_table :log_tags do |t|
      t.string :tag
      t.string :host
      t.string :object_type
      t.string :uuid
      t.timestamps
    end
  end

  def self.down
    drop_table :log_tags
  end
end