require 'spec_helper'

describe CollectionGroup do

  describe "basic creation" do
    it "no name : should not create the collection group and raise error" do
      cg = CollectionGroup.new
      cg.save
      cg.errors.size.should == 1
      cg.errors.full_messages[0].should match(/Name/)
    end
    it "duplicate : should not create the collection group and raise error" do
      cg1 = CollectionGroup.new
      cg2 = CollectionGroup.new
      cg1.name = "test"
      cg1.save
      cg1.errors.size.should == 0
      cg2.name = "test"
      cg2.save
      cg2.errors.size.should == 1
      cg2.errors.full_messages[0].should match(/Name.*pas disponible/)
    end

  end

  describe "relations with collections through relation table" do
    before(:all) do
      5.times do
        Factory(:collection_group_with_members_seq)
      end
    end
    after(:all) do
      CollectionGroup.destroy_all
      Collection.destroy_all
      CollectionGroupMember.destroy_all
    end
    it "should return the collections" do
      cg = CollectionGroup.find(:first)
      cg.collections.size.should == 2
      cg.collections[0].should be_a(Collection)
    end
  end

  describe "pagination with will_paginate" do

    before(:all) do
      25.times do
        Factory(:collection_group_seq)
      end
    end
    after(:all) do
      CollectionGroup.destroy_all
    end
    it "should return paginated models" do
      page = CollectionGroup.paginate(:page=>1,:per_page => 20)
      page.size.should == 20
      page = CollectionGroup.paginate(:page=>1,:per_page => 20).order('name asc')
      page[0].name.should match(/collection_group_/)
      page.total_pages.should == 2
      page.current_page.should == 1
      page.previous_page.should be_nil
      page.next_page.should_not be_nil
      page.next_page.should == 2
      page.offset.should == 0
      page.total_entries.should == 25
    end

    it "should apply conditions and return 11 collections" do
      page = CollectionGroup.paginate(:page=>2,:per_page => 3).where("name like ?", ["collection_group_1%"])
      page.size.should == 3
      page.current_page.should == 2
      page.offset.should == 3
      page.total_pages.should == 4
      page.total_entries.should == 10

      page = CollectionGroup.paginate(:page=>2,:per_page => 3).where("")
      page.size.should == 3
      page.current_page.should == 2
      page.offset.should == 3
      page.total_pages.should == 9
      page.total_entries.should == 25

    end
  end

end
