# generated file
require 'spec_helper'
require 'check_helper'
require 'portfolio_search_class.rb'

describe PortfolioSearchClass do
  include CheckHelper
  describe "SearchCollection" do
    without_transactional_fixtures do
      before(:each) do 
        CACHE.delete("10_1")
        @collection = Factory(:portfolio_collection)
        @ids = []
        10.times do
          c = Factory(:metadatas, :collection_id=>@collection.id)
          @ids << c.dc_identifier
          p = Factory(:portfolio_datas,
                      :dc_identifier=>c.dc_identifier, 
                      :metadata_id => c.id)
          3.times do |n|
            v = Factory(:volumes, 
                        :number=>n,
                        :collection_id=>@collection.id,
                        :dc_identifier=>c.dc_identifier, 
                        :metadata_id => c.id)
          end
        end

      end
      it "should return records (no action_type)" do
        klass = PortfolioSearchClass.new
        klass.bfound = true
        klass.list_of_ids = @ids

        records = klass.SearchCollection(@collection, ["keyword"], ["johnson"], 0, 100, [], 10)
        records.should be_a(Array)
        records.size.should == 10
        records[0].should be_a(Record)
        records[9].should be_a(Record)
        check_metadata_record(records[5])
        check_volumes_record(records[9])
       
      end
      it "should return an id, hits and total_hits (action_type set)" do
        klass = PortfolioSearchClass.new
        klass.bfound = true
        klass.list_of_ids = @ids
        id, hits, total_hits = klass.SearchCollection(@collection, ["keyword"], ["jack"], 0, 100, [], 10, -1, nil, nil, nil, "test")
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
        check_volumes_record(Record.new(parsed_records[6]))     
      end
    end
  end
end