class UpdateJobQueuesAddTotalHits < ActiveRecord::Migration
  def self.up
    add_column :job_queues, :total_hits, :integer, :default => 0
  end

  def self.down
    remove_column :job_queues, :total_hits
  end
end