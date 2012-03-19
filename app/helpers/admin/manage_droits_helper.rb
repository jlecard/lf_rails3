
module Admin::ManageDroitsHelper
    def GetCollectionNotDefineForRoleByLocation(idRole, idLocation)
        begin
            id = ManageDroit.find(:all, :select => "id_collection", :conditions => {:id_role => idRole, :id_lieu => idLocation});
            collection = Array.new();
            puts "list id : ";
            id.each do |elem|
                puts "====> : #{elem.id_collection}";
                collection.push(elem.id_collection);
            end
            
            if (collection.length == 0)
                return (@collection);
            end
            return (Collection.find(:all, :conditions => "id not in (" + collection.join(', ') + ")"));
        rescue
            return (@collection);
        end
    end
end
