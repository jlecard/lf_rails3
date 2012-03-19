class CreateRejects < ActiveRecord::Migration
  def self.up
    create_table :rejects do |t|
      t.column :name, :string
      t.column :data, :string
      t.timestamps
    end
  end
  
  def self.down
    drop_table :rejects
  end
end
