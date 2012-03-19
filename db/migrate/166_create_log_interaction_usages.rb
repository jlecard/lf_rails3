class CreateLogInteractionUsages < ActiveRecord::Migration
  def self.up
    create_table :log_interaction_usages do |t|
      t.string :idObject
      t.integer :object_type
      t.integer :interaction_type
      t.integer :movement
      t.string :host
      t.string :uuid, :default => nil
      t.timestamps
    end
  end

  def self.down
    drop_table :log_interaction_usages
  end
end
