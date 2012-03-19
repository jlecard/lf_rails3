
class UpdateCollectionGroupsAddRank < ActiveRecord::Migration
  
  def self.up
    add_column(:collection_groups, :rank, :integer)
    oElem = CollectionGroup.find(:all, :order => 'tab_id, name')
	if !oElem.nil? && !oElem.empty?
	
      lastParentId = oElem[0].tab_id
      inc = 1;
      oElem.each do |value|
        if (lastParentId != value.tab_id)
          lastParentId = value.tab_id
          inc = 1;
        end
		value.rank = inc;
		inc += 1;
		value.save();
	  end
	end
  end
  
  def self.down
    remove_column (:collection_groups, :rank)
  end
  
end
