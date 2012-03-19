class UpdateJobQueuesAddDatetime < ActiveRecord::Migration
  
  def self.up
    add_column :job_queues, :timestamp, :string
  end
  
  def self.down
    remove_column :job_queues, :string
  end
  
end