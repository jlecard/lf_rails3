class UpdateObjectsTagsState < ActiveRecord::Migration
  def self.up
    rename_column :objects_tags, :state_manager, :workflow_manager
    rename_column :objects_tags, :state_date, :workflow_date
  end

  def self.down
    rename_column :objects_tags, :workflow_date, :state_date
    rename_column :objects_tags, :workflow_manager, :state_manager
  end
end