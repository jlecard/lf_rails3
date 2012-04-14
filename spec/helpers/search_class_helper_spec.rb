require 'spec_helper'

describe SearchClassHelper do
  describe "SearchCollection" do
    collection = Factory(:oai_collection)
    it "should raise a no method error" do   
      lambda { SearchCollection(collection, ["keyword"], ["john"], 0, 100, ["OR"], "search_id") }.should raise_error NoMethodError
    end
    
    it "should initialize a search" do
      klass = OaiSearchClass.new
      klass.SearchCollection(collection, ["keyword"], ["john"], 0, 100, ["OR"], "search_id") 
      klass.records.should be_a(Array)
    end
  end
  
  describe "save_in_cache" do
    it "should raise an NameError" do
      lambda{ save_in_cache }.should raise_error NameError
    end
    it "should save cached data" do
      collection = Factory(:oai_collection)
      klass = OaiSearchClass.new
      klass.collection = collection
      search_id, hits, total_hits = klass.save_in_cache
      search_id.should == "_1"
      hits.should == 0
      total_hits.should == 0
      klass.records.should be_nil
    end
  end
end