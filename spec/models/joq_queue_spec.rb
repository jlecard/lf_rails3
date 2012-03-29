require 'spec_helper'
require 'spawn'
require 'cached_search'

include Spawn
describe JobQueue do
  before(:each) do
    @collection = Factory(:collection)
    @collection_group = Factory(:collection_group)
    @assoc = Factory(:collection_group_member, :collection_group=>@collection_group,:collection=>@collection)
    @job_id = JobQueue.create_job(@collection.id, 0, 0, @collection.alt_name)
  end

  it "should have the values specified + defaults" do
    job = JobQueue.find(@job_id)
    job.database_name.should == "keesings"
    job.collection_id.should == @collection.id
    job.total_hits.should == 0
    job.status.should == 1
    job.hits.should == 0
    job.thread_id == 0
    job.records_id.should == "0"
    job.errors.should be_a(ActiveModel::Errors)
    job.errors.count.should == 0
  end
  
  describe "update_job : Updates the job within a spawned process" do
    without_transactional_fixtures do
      it "Updates the job with given values" do
        JobQueue.update_job(@job_id, 3443, "roro", 4, 10,23, "bang")
        job = JobQueue.find(@job_id)
        job.database_name.should == "roro"
        job.collection_id.should == @collection.id
        job.total_hits.should == 23
        job.status.should == 4
        job.hits.should == 10
        job.thread_id == 0
        job.records_id.should == "3443"
        job.error.should == "bang"
        job.errors.count.should == 0
      end

      it "Updates the job within a spawned process" do
        spawn_b = spawn_block do
          JobQueue.update_job(@job_id, 3443, "roro", 4, 10,23, "bang")
        end
        wait([spawn_b])
        job = JobQueue.find(@job_id)
        job.database_name.should == "roro"
        job.collection_id.should == @collection.id
        job.total_hits.should == 23
        job.status.should == 4
        job.hits.should == 10
        job.thread_id == 0
        job.records_id.should == "3443"
        job.error.should == "bang"
        job.errors.count.should == 0
        JobQueue.find(@job_id).destroy
        @collection.destroy
        @collection_group.destroy
        @assoc.destroy
      end
    end
  end

  describe "retrieve_metadata" do
    without_transactional_fixtures do
      before(:all) do
        CACHE.delete("my_smart_key")
      end
      it "retrieves data associated to a job" do
        job = Factory(:job_queue)
        metadata = [Record.new, Record.new,Record.new]
        record = InCacheRecord.new(metadata, 150, 12, 0, 3023)
        CACHE.set("my_smart_key", record)
        records = JobQueue.retrieve_metadata(job.id, 200, 0, nil)
        records.should_not be_nil
        records.should be_a(InCacheRecord)
        records.data.should_not be_nil
        records.data.size.should == 3
        records.data[0].should be_a(Record)
      end
    end
  end
end