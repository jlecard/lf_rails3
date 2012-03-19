
class Update3SearchTabSubjects < ActiveRecord::Migration

  def self.up
    add_column(:search_tab_subjects, :rank, :integer)
		oElem = SearchTabSubject.find(:all, :order => 'parent_id, id')
		if (!oElem.nil? && !oElem.empty?)
			lastParentId = oElem[0].parent_id;
			inc = 1;
			oElem.each do |value|
				if (lastParentId != value.parent_id)
						lastParentId = value.parent_id;
						inc = 1;
				end
				value.rank = inc;
				if (inc < 50)
					inc += 1;
				end
				value.save();
			end
		end
  end
  
  def self.down
    remove_column (:search_tab_subjects, :rank)
  end

end
