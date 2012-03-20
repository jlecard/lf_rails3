require "#{File.dirname(__FILE__)}/../test_helper"
require 'timeout'
class AdminSimpleTest < ActionController::IntegrationTest
  use_transactional_fixtures = false
  fixtures :collections, :collection_groups, :collection_group_members, :metadatas, :portfolio_datas, :controls, :volumes
  
  def test_search
    data = Metadata.find(:all, :conditions=>{:collection_id=>5})
    assert(data.count > 0)
    data = nil
    obj = MetaSearch.new
    sets = "g593" # Catalogue Bpi
    _qtype = ["keyword"]
    _qstring = ["ferme"]
    _start = 0
    _max = 100
    _qoperator = ["OR"]
    ids = obj.SearchAsync(sets, _qtype, _qstring, _start, _max, _qoperator, options=nil, _session_id=nil, _action_type=1, _data = nil, _bool_obj=true)
    assert_equal([1],ids)
    jobqueue = JobQueue.find(1)
    assert_kind_of(JobQueue, jobqueue)
    assert_equal("Catalogue Bpi", jobqueue.database_name)
    assert_equal(5, jobqueue.collection_id)
    assert_equal(1, jobqueue.status)
    assert_equal("0", jobqueue.records_id)
    assert_equal(0, jobqueue.hits)
    assert_equal(0, jobqueue.total_hits)
    sleep(60)
    jobqueue = JobQueue.find(1)
    @cached_id = jobqueue.records_id if (jobqueue.records_id != "0" or jobqueue.records_id != 0)  
    assert_match(/.*_5$/, jobqueue.records_id)
    assert_equal(0, jobqueue.status)
    
  end
  
  def teardown()
    @cached_id = "b5a70219a22c0259e536c00a3bc347e3d601bd87_5"
    ActiveRecord::Base.connection.execute("truncate job_queues")
    ActiveRecord::Base.connection.execute("truncate cached_searches")
    ActiveRecord::Base.connection.execute("truncate cached_records")
    puts "deleting cached record #{@cached_id}"
    CACHE.delete(@cached_id) if @cached_id
  end
  
end