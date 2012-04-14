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
        check_search_collection_records(records)
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
        check_search_collection_cached_records(id, hits, total_hits)       
      end
    end
  end
  

end