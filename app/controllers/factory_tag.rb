class FactoryTag < ActiveRecord::Base
  
  # Create tag structure
  #   params :
  #     tag : required (id, label, weight)
  #     object_tag_struct : optional (ObjectTagStruct to know if authenticated user has tagged this tag for current object or not (nuage tag))  
  #     lists_count : required (Integer, count of lists referenced by tag = public references + those referenced by authenticated user)
  #     notices_count : required (Integer, count of notices referenced by tag = public references + those referenced by authenticated user)
  #     simple_lists : optional (Array containing lists refrenced by this tag = public references + those referenced by authenticated user)
  #     simple_notices : optional (Array containing notices referenced by this tag = public references + those referenced by authenticated user)
  #     other_users_objects : optional (Array containing objects referenced by other users)
  def self.createTag(tag, tag_weight, object_tag_struct = nil, lists_count = 0, notices_count = 0, simple_lists = [], simple_notices = [], other_users_objects = [])
    if tag.nil?
      return nil;
    end  
    t = Struct::TagStruct.new();  
    t.id = tag.id;
    t.label = tag.label;
    t.weight = tag_weight;
    t.lists_count = lists_count    
    t.notices_count = notices_count
    t.user_object_tag = object_tag_struct
    t.simple_lists = simple_lists
    t.simple_notices = simple_notices
    t.other_users_objects = other_users_objects
    return t
  end
  
end