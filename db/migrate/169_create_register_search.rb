class CreateRegisterSearch < ActiveRecord::Migration
  def self.up
    create_table :register_search do |t|
      t.integer :mode
      t.integer :mobile
      t.string :sort_type
      t.string :uuid
      t.string :collection
      t.datetime :search_last_date
    end
  end

  def self.down
    drop_table :register_search
  end
end
