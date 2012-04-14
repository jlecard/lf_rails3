#encoding:utf-8
module CheckHelper
  
  def check_search_collection_records(records)
    records.should be_a(Array)
    records.size.should == 10
    records[0].should be_a(Record)
    records[9].should be_a(Record)
    check_metadata_record(records[5])
  end
  
  def check_search_collection_cached_records(id, hits, total_hits)
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
    rec = Record.new(parsed_records[6])
    check_volumes_record(rec) if !rec.examplaires.empty? 
  end
  
  def check_metadata_record(record)
    record.title.should == "johnson title"
    record.material_type.should == "Livre"
    record.subject.should == "johnson subject"
    record.author.should == "johnson creator"
    record.abstract.should == "johnson desc"
    record.publisher.should == "johnson"
    record.contributor.should == "johnson"
    record.format.should == "johnson format"
    record.source.should == "johnson"
    record.relation.should == "johnson"
    record.coverage.should == "johnson"
    record.rights.should == "johnson"
    record.volume.should == "johnson"
    record.openurl.should == "johnson"
    record.link.should == ""
    record.lang.should == "Français"
  end

  def check_volumes_record(record)
    record.examplaires.should be_a(Array)
    i = 0
    record.examplaires.each do |ex|
      ex = Examplaire.new(ex) if ex.instance_of?(Hash)
      ex.number.should == i
      ex.call_num.should == "johnson"
      ex.availability.should == "online"

      ex.location.should == "johnson"
      ex.label.should == "johnson"

      ex.link_label.should == "johnson"
      ex.launch_url.should == "johnson"
      ex.link.should == "johnson"
      ex.support.should == "johnson"
      i += 1
    end

  end

end