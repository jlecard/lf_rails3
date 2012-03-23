require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the RecordHelper. For example:
#
# describe RecordHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end
describe RecordHelper do
  describe "default_tab" do
    it "returns 1 if no parameters specified" do
      id_tab = helper.default_tab
      id_tab.should == "1"
    end
    
    it "returns a tab id if parameters specified" do
      params[:idTab] = "4"
      id_tab = helper.default_tab
      id_tab.should == "4"
    end
    
    it "returns affected tab id (no parameters specified)" do
      @idTab = "4"
      id_tab = helper.default_tab
      id_tab.should == "4"
    end
    
    it "returns affected tab id (with parameters specified)" do  
      @idTab = "6"
      params[:idTab] = "10"
      id_tab = helper.default_tab
      id_tab.should == "6"
    end
  end
end
