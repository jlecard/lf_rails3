class Tag < ActiveRecord::Base
  
  has_many :objects_tags, :foreign_key => :tag_id, :dependent => :destroy
  has_many :objects_counts, :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_TAG} "
  
  # Return tag if it's label exists
  def self.getTagByLabel?(label)
    format = UtilFormat.remove_accents(label).downcase
    return Tag.find(:first, :conditions => ["label_format = ?", format])
  end
  
  def self.getTagById(tag_id)
    return Tag.find(tag_id)
  end
  
  # Create Tag
  def self.createTag(label)
    format = UtilFormat.remove_accents(label).downcase
    tag = Tag.new
    tag.label = label    
    tag.label_format = format    
    tag.save!
    return tag
  end
  
  # Delete tag  
  def self.deleteTagById(id)
    Tag.destroy(id)
  end
  
  
  # tagsAutoComplete  
  def self.tagsAutoComplete(label)
    Tag.find_by_sql ["select id, label From tags where label_format LIKE ?", label.downcase + '%' ]
  end
 
  
  # Method getTagsByObject
  def self.getTagsByObject(object_type, object_uid, uuid, sort = SORT_TAG_ALPHABETIC, direction = DIRECTION_UP, offset = 0, limit = DEFAULT_MAX_TAG)
    query = "SELECT t.id as id, t.label as label, count(o.tag_id) as tag_weight FROM tags t, objects_tags o "
    query += "WHERE t.id = o.tag_id and t.id IN "
    query += "(SELECT tag_id from objects_tags WHERE object_uid = '#{object_uid}' and object_type = #{object_type} "
    query += " AND (state = #{TAG_PUBLIC} or uuid = '#{uuid}')) "
    query += " GROUP BY label order by #{sort} "

    if(direction == DIRECTION_DOWN)
      query += " DESC "
    end
    query += " limit #{offset},#{limit}" 
    tags = ObjectsTag.find_by_sql(query)
    
    return tags;
  end
  
  # Method getTagsByUser
  def self.getTagsByUser(uuid, state_tag, sort = SORT_TAG_ALPHABETIC, direction = DIRECTION_UP, offset = 0, limit = DEFAULT_MAX_TAG)
    query = " SELECT t.id, t.label, COUNT(t.id) as tag_weight FROM tags t, objects_tags ot WHERE t.id = ot.tag_id AND ot.uuid = '#{uuid}' "
   
    if (!state_tag.nil?)
      query += " AND ot.state = #{state_tag} "
    end
    
    query += "GROUP BY t.id ORDER BY #{sort} "
    if (direction == "down")
      query += " DESC"
    end
    
    query += ", t.id ASC"
    
    query += " limit #{offset},#{limit} "
    tags = ObjectsTag.find_by_sql(query)
    return tags;    
  end
  
  # Method getNoticesCountByUser
  def self.getNoticesCountByUser(tag, uuid, state_tag)
    query = " SELECT count(object_uid) as notices_count FROM objects_tags WHERE object_type = #{ENUM_NOTICE} AND tag_id = #{tag.id} AND uuid = '#{uuid}' " 
    if (!state_tag.nil?)
      query += " AND state = #{state_tag} "
    end
    obj_tag = ObjectsTag.find_by_sql(query);
    obj_tag.each do |ot|
      if (ot.nil?)
        return 0;
      end    
      return ot.notices_count.to_i;  
    end
  end
  
  def self.updateAllUserTagsState(uuid, state)
    ObjectsTag.update_all("state = #{state}", "uuid = '#{uuid}'")
  end
  
  # Method getListsCountByUser
  def self.getListsCountByUser(tag, uuid, state_tag)
    query = " SELECT count(object_uid) as lists_count FROM objects_tags WHERE object_type = #{ENUM_LIST} AND tag_id = #{tag.id} AND uuid = '#{uuid}' "
    if (!state_tag.nil?)
      query += " AND state = #{state_tag} "
    end
    obj_tag = ObjectsTag.find_by_sql(query);
    obj_tag.each do |ot|
      if (ot.nil?)
        return 0;
      end
      return ot.lists_count.to_i;
    end
  end
  
end