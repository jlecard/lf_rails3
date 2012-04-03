require 'spec_helper'

describe Z3950SearchClass do
  describe "SearchCollection" do
    without_transactional_fixtures do
      it "should trigger a search on a given collection" do
        klass = Z3950SearchClass.new
        collection = Factory(:z3950_collection)
        my_id, hits, total_hits = klass.SearchCollection(collection, ["keyword"], ["johnson"], 0, 100, [], 10)
        p my_id
        p hits
        p total_hits
        hits.should_not == 0
        total_hits.should_not == 0
        
      end
    end
  end
end