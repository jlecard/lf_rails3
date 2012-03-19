class CreateLogSearch < ActiveRecord::Migration
  def self.up
    create_table :log_searches do |t|
      t.string :host
      t.integer :search_history_id
      t.timestamps
    end
  end

  def self.down
    drop_table :log_searches
  end
end