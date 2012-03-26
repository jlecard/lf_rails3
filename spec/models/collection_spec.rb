require 'spec_helper'



describe Collection do
  describe "pagination with will_paginate" do

    before(:all) do
      25.times do
        Factory(:collection_seq)
      end
    end
    after(:all) do
      Collection.destroy_all
    end
    it "should return paginated models" do
      page = Collection.paginate(:page=>1,:per_page => 20)
      page.size.should == 20
      page = Collection.paginate(:page=>1,:per_page => 20).order('name asc')
      page[0].name.should == "collection_1"
      page.total_pages.should == 2
      page.current_page.should == 1
      page.previous_page.should be_nil
      page.next_page.should_not be_nil
      page.next_page.should == 2
      page.offset.should == 0
      page.total_entries.should == 25
    end

    it "should apply conditions and return 11 collections" do
      page = Collection.paginate(:page=>2,:per_page => 3).where("name like ?", ["collection_1%"])
      page.size.should == 3
      page.current_page.should == 2
      page.offset.should == 3
      page.total_pages.should == 4
      page.total_entries.should == 11
      
      page = Collection.paginate(:page=>2,:per_page => 3).where("")
      page.size.should == 3
      page.current_page.should == 2
      page.offset.should == 3
      page.total_pages.should == 9
      page.total_entries.should == 25

    end
  end

end
