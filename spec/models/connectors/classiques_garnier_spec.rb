# generated file
require 'spec_helper'
require 'check_helper'
require 'classiques_garnier_search_class'


describe ClassiquesGarnierSearchClass do
  describe "SearchCollection" do
    include CheckHelper
    without_transactional_fixtures do
      it "should return records (no action_type)" do
        collection = Factory(:classiques_garnier_collection)
        ids = []
        10.times do
          c = Factory(:metadatas, :collection_id=>collection.id)
          c.save
          ids << c.dc_identifier
        end
        klass = ClassiquesGarnierSearchClass.new
        klass.bfound = true
        klass.list_of_ids = ids
        
        records = klass.SearchCollection(collection, ["keyword"], ["johnson"], 0, 100, [], 10)
        records.should be_a(Array)
        records.size.should == 10
        records[0].should be_a(Record)
        records[9].should be_a(Record)
        check_metadata_record(records[5])
      end
      
      it "should return an id, hits and total_hits (action_type set)" do
        collection = Factory(:classiques_garnier_collection)
        klass = ClassiquesGarnierSearchClass.new
        ids = []
        10.times do
          c = Factory(:metadatas, :collection_id=>collection.id)
          ids << c.dc_identifier
        end
        
        klass.list_of_ids = ids
        klass.bfound = true
        id, hits, total_hits = klass.SearchCollection(collection, ["keyword"], ["jack"], 0, 100, [], 10, -1, nil, nil, nil, "test")
        id.should match(/^\d+_\d+$/)
        hits.should == 10
        total_hits.should == 10
        records = CACHE.get(id)
        records.should be_a(InCacheRecord)
        records.max.should == 100
        records.total_hits.should == total_hits
        records.status.should == 0
        parser = Yajl::Parser.new
        parsed_records = parser.parse(records.data)
        parsed_records.should be_a(Array)
        check_metadata_record(Record.new(parsed_records[5]))        
      end
    end
  end
  

end