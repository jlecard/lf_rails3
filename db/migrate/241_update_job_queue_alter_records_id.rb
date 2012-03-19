class UpdateJobQueueAlterRecordsId < ActiveRecord::Migration
  def self.up
    change_column :job_queues, :records_id, :string
  end
  
  def self.down
    change_column :job_queues, :records_id, :integer
  end
end
