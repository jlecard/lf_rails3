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
        check_search_collection_records(records)
        check_volumes_record(records[9])
      end
      
      it "should return an id, hits and total_hits (action_type set)" do
        klass = PortfolioSearchClass.new
        klass.bfound = true
        klass.list_of_ids = @ids
        id, hits, total_hits = klass.SearchCollection(@collection, ["keyword"], ["jack"], 0, 100, [], 10, -1, nil, nil, nil, "test")
        check_search_collection_cached_records(id, hits, total_hits)
      end
    end
  end
end