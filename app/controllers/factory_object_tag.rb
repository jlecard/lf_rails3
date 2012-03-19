class FactoryObjectTag < ActiveRecord::Base
  
  def self.createObjectTag(object_tag, community_user, title = nil)
    if object_tag.nil?
      return nil
    end
    if(community_user.nil?)
      return nil
    end
    ot = Struct::ObjectTagStruct.new()
    ot.id = object_tag.id
    ot.state = object_tag.state
    ot.uuid = community_user.uuid
    ot.user_name = community_user.name 
    ot.date = object_tag.tag_date
    ot.object_type = object_tag.object_type
    ot.object_uid = object_tag.object_uid
    ot.tag_id = object_tag.tag_id
    ot.title = title
    return ot
  end

end