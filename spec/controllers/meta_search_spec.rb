require 'spec_helper'
require 'timeout'

describe MetaSearch do
  describe "basic search_async" do

    without_transactional_fixtures do
      before(:each) do
        @collection = Factory(:collection)
        @collection_group = Factory(:collection_group)
        @assoc = Factory(:collection_group_member, :collection_group=>@collection_group,:collection=>@collection)
        CACHE.delete(1)
        CACHE.delete("de379b4865d0543e7c0b017db58c9d528bbf7133_1")
        CACHE.delete("de379b4865d0543e7c0b017db58c9d528bbf7133")
        CACHE.delete("de379b4865d0543e7c0b017db58c9d528bbf7133=10")
        CACHE.delete("e272d21eefd9fafee3590d3ed1e0f14deb16d63d")
      end

      it "should trigger a search and return a valid job_id" do
        m = MetaSearch.new
        jobs = m.search_async("g#{@assoc.collection_group_id}", ["keyword"], ["Johnson"], 0, 10, ["AND"])
        jobs.should_not be_nil
        created_jobs = JobQueue.find(jobs)
        created_jobs.count.should == 1
        created_jobs[0].should be_a(JobQueue)
        created_jobs[0].status.should == 1
      end

      it "should trigger a search and return a valid job_id, search should return results" do
        m = MetaSearch.new
        jobs = m.search_async("g#{@assoc.collection_group_id}", ["keyword"], ["Johnson"], 0, 10, ["AND"])
        jobs.should_not be_nil
        jobstatus = m.check_job_status(jobs)[0]
        # wait for results
        Timeout::timeout(30) do
          break if jobstatus.status == 0
          while (jobstatus.status == JOB_WAITING) do
            jobstatus = m.check_job_status(jobs)[0]
            jobstatus.should be_a(JobQueue)
            sleep(1)
          end
        end
        # test results (job)
        jobstatus.status.should == 0
        jobstatus.hits.should == 10
        jobstatus.total_hits.should == 10
        # retrieve results (! results titles subject to change)
        rec = m.get_jobs_records(jobs, 10)
        rec.should_not be_nil
        rec.size.should == 10
        first = rec[0]
        first.should be_a(Record)
        first.title.should == "Assassination of President Kennedy (United States)"
        last = rec[9]
        last.should be_a(Record)
        last.title.should match(/^The Dean of Canterbury's Allegations/)
      end
    end
  end
end
