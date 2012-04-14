# generated file
require 'spec_helper'
require 'check_helper'
require 'ged_search_class.rb'

describe GedSearchClass do
  describe "SearchCollection" do
    include CheckHelper
    without_transactional_fixtures do
      before(:each) do
        CACHE.delete("10_1")
        @collection = Factory(:ged_collection)
        @ids = []
        10.times do
          c = Factory(:metadatas, :collection_id=>@collection.id)
          @ids << c.dc_identifier
        end

      end
      it "should return records (no action_type)" do
        klass = GedSearchClass.new
        klass.list_of_ids = @ids
        records = klass.SearchCollection(@collection, ["keyword"], ["johnson"], 0, 100, [], 10)
        check_search_collection_records(records)
      end
      it "should return an id, hits and total_hits (action_type set)" do
        klass = GedSearchClass.new
        klass.list_of_ids = @ids
        id, hits, total_hits = klass.SearchCollection(@collection, ["keyword"], ["jack"], 0, 100, [], 10, -1, nil, nil, nil, "test")
        check_search_collection_cached_records(id, hits, total_hits)
      end
    end
  end
end