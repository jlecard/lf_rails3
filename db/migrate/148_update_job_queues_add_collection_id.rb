class UpdateJobQueuesAddCollectionId < ActiveRecord::Migration
  def self.up
    add_column :job_queues, :collection_id, :integer, :null=>false
    add_index :job_queues, :collection_id
  end

  def self.down
    remove_column :job_queues, :collection_id
  end
end