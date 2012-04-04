require 'spec_helper'
require 'em_consulte_search_class'

describe EmconsulteSearchClass do
  describe "SearchCollection" do
    without_transactional_fixtures do
      it "should return records (no action_type)" do
        klass = EmconsulteSearchClass.new
        collection = Factory(:em_consulte_collection)
        records = klass.SearchCollection(collection, ["keyword"], ["johnson"], 0, 100, [], 10)
        records.should be_a(Array)
        records.size.should == 100
        records[0].should be_a(Record)
        records[99].should be_a(Record)
      end
      it "should return an id, hits and total_hits (action_type set)" do
        klass = EmconsulteSearchClass.new
        collection = Factory(:z3950_collection)
        id, hits, total_hits = klass.SearchCollection(collection, ["keyword"], ["jack"], 0, 100, [], 10, -1, nil, nil, nil, "test")
        id.should match(/^\d+_\d+$/)
        hits.should == 100
        total_hits.should > 100
        records = CACHE.get(id)
        records.should be_a(InCacheRecord)
        records.max.should == hits
        records.total_hits.should == total_hits
        records.status.should == 0
      end
    end
  end
end