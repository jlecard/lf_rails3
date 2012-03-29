require 'spec_helper'
require "#{Rails.root}/app/models/struct/http_user_params"
require 'spawn'



include Spawn


describe CachedSearch do

  describe "hash_key" do
    it "should return a valid hash key" do
      key, query, type = CachedSearch.hash_key(["test"],["keyword"],"g1",100,nil)
      key.should == "c5de9fc4baa0b56f97e272683020d2f2f06dda17"
      query.should == "test"
      type.should == "keyword"
    end
    it "should return a valid hash key (with http request user params)" do
      user_info = HttpUserParams.new( :state_user=>"bingo",
      :location_user=>"BUREAU")
      key, query, type = CachedSearch.hash_key(["test"],["keyword"],"g1",100,user_info)
      key.should == "72cd7f8c7f5db39788f0cba39d81775efbfceca2"
      query.should == "test"
      type.should == "keyword"
    end
  end

  describe "set_query" do
    it "should store a key in memcache" do
      key, max = CachedSearch.set_query(["test"],["keyword"],"g1",100,nil )
      key.should_not be_nil
      max.should == 100
      CACHE.get(key).should == 100
      key.should == "c5de9fc4baa0b56f97e272683020d2f2f06dda17"
    end

    it "should store a key in memcache with http_params" do
      user_info = HttpUserParams.new( :state_user=>"bingo",
      :location_user=>"BUREAU")
      key, max = CachedSearch.set_query(["test"],["keyword"],"g1",100,user_info)
      key.should == "72cd7f8c7f5db39788f0cba39d81775efbfceca2"
      max.should == 100
    end
  end

  describe "check_cache" do
    it "should retrieve keys previously stored" do
      key, val = CachedSearch.check_cache(["test"],["keyword"],"g1",100,nil )
      key.should == "c5de9fc4baa0b56f97e272683020d2f2f06dda17"
      val.should == 100
    end
    it "should retrieve keys previously stored with http params" do
      user_info = HttpUserParams.new( :state_user=>"bingo",
      :location_user=>"BUREAU")
      key, val = CachedSearch.check_cache(["test"],["keyword"],"g1",100,user_info)
      key.should == "72cd7f8c7f5db39788f0cba39d81775efbfceca2"
      val.should == 100
    end
  end

  describe "build_cache_xml" do
    it "should encode to json" do
      rec1 = Record.new
      rec1.title = "haha"
      rec2 = Record.new
      rec2.title = "hoho"
      records = [rec1,rec2]
      json_records = CachedSearch.build_cache_xml(records)
      json_records.should == "[{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"haha\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"},{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"hoho\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"}]"
    end
  end

  describe "save_metadata" do
    it "should store json formatted records into cache" do
      100.times do |n|
        json_records = "[{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"haha\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"},{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"hoho\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"}]"
        key = CachedSearch.save_metadata("search_id_key", json_records, n, n, 0)
        key.should == "search_id_key_#{n}"
        cached_rec = CACHE.get("search_id_key_#{n}")
        check_cached_record(cached_rec, n)
      end
    end
  end

  describe "retrieve_metadata" do
    it "should retrieve the cached record previously created" do
      100.times do |n|
        cached_rec = CachedSearch.retrieve_metadata("search_id_key", n, n)
        check_cached_record(cached_rec, n)
      end
    end
  end

  describe "save_execution_time" do
    it "should update the record in cache" do
      100.times do |n|
        CachedSearch.save_execution_time("search_id_key", n, n)
        cached_rec = CACHE.get("search_id_key_#{n}")
        cached_rec.should be_a(InCacheRecord)
        cached_rec.search_time.should == n
      end
    end
  end

  describe "save and retrieve metadata in different processes" do
    it "launches 100 processes and saves metadata" do
      spawn_blocks = []
      json_records = "[{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"haha\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"},{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"hoho\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"}]"
      100.times do |i|
        spawn_blocks[i] = spawn_block do
          key = CachedSearch.save_metadata("search_spawn_id_key", json_records, i, i, 0)
          key.should == "search_spawn_id_key_#{i}"
        end
        #wait(spawn_blocks)
        cached_rec = CachedSearch.retrieve_metadata("search_spawn_id_key", i, i)
        check_cached_record(cached_rec, i)
      end
    end
  end
end

def check_cached_record(cached_rec, n)
  json_records = "[{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"haha\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"},{\"rank\":\"\",\"hits\":\"\",\"ptitle\":\"\",\"title\":\"hoho\",\"atitle\":\"\",\"isbn\":\"\",\"issn\":\"\",\"abstract\":\"\",\"date\":\"\",\"author\":\"\",\"link\":\"\",\"id\":\"\",\"source\":\"\",\"doi\":\"\",\"openurl\":\"\",\"direct_url\":\"\",\"thumbnail_url\":\"\",\"static_url\":\"\",\"subject\":\"\",\"publisher\":\"\",\"relation\":\"\",\"contributor\":\"\",\"coverage\":\"\",\"rights\":\"\",\"callnum\":\"\",\"material_type\":\"\",\"format\":\"\",\"vendor_name\":\"\",\"vendor_url\":\"\",\"volume\":\"\",\"issue\":\"\",\"number\":\"\",\"page\":\"\",\"start\":\"\",\"end\":\"\",\"holdings\":\"\",\"raw_citation\":\"\",\"oclc_num\":\"\",\"theme\":\"\",\"category\":\"\",\"lang\":\"\",\"identifier\":\"\",\"availability\":\"\",\"is_available\":true,\"examplaires\":[],\"notice\":null,\"actions_allowed\":true,\"date_end_new\":\"\",\"date_indexed\":\"\",\"indice\":\"\",\"issue_title\":\"\",\"conservation\":\"\"}]"
  cached_rec.should be_a(InCacheRecord)
  cached_rec.data.should == json_records
  cached_rec.status.should == 0
  cached_rec.collection_id.should == n
  cached_rec.max.should == n
  cached_rec.total_hits.should == 0
end