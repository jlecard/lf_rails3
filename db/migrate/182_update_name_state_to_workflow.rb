class UpdateNameStateToWorkflow < ActiveRecord::Migration
  def self.up
    add_column :objects_tags, :workflow, :integer, :default => 0
    add_column :comments, :workflow, :integer, :default => 0    
    rename_column :comments, :state_manager, :workflow_manager
    rename_column :comments, :state_date, :workflow_date
  end

  def self.down
    remove_column :objects_tags, :workflow
    remove_column :comments, :workflow
    rename_column :comments, :workflow_date, :state_date
    rename_column :comments, :workflow_manager, :state_manager
  end
end