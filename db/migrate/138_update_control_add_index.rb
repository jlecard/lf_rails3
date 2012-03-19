class UpdateControlAddIndex < ActiveRecord::Migration
  def self.up
		add_index :controls, :collection_id
  end

  def self.down
		remove_index :controls, :collection_id
  end
end
