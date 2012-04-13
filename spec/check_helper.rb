#encoding:utf-8
module CheckHelper
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