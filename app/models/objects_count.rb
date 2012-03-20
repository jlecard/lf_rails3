class ObjectsCount < ActiveRecord::Base
  
  belongs_to :community_users, :foreign_key => :object_uid, :conditions => " object_type = #{ENUM_COMMUNITY_USER} "
  
  def self.createCount(object_type, object_uid)
    logger.debug("[ObjectsCount][createCount] object_type = #{object_type} and object_uid = #{object_uid} ")
    obj = ObjectsCount.find(:first, :conditions => " object_type = #{object_type} AND object_uid = '#{object_uid}'")
    if(obj.nil?)
      o = ObjectsCount.new()
      o.object_type = object_type
      o.object_uid = object_uid.to_s
      o.save
      return o
    end
  end
  
  
  def self.getCustomObjectId(object_type, object_uid)
    if( object_type == ENUM_NOTICE )
      doc_id, doc_collection_id = UtilFormat.parseIdDoc(object_uid)
      return "#{doc_id},#{doc_collection_id}"
    end
    return object_uid
  end
  
  
  # Method incrementObjectsCount (count_type : LIST or NOTICE or SUBSCRIPTION or TAG or COMMENT)
  def self.incrementObjectsCount(object_type, object_uid, count_type, objects_count, state=0)
    begin
      obj = ObjectsCount.find(:first, :conditions => " object_type = #{object_type} and object_uid = '#{getCustomObjectId(object_type,object_uid)}' ");
      if(obj.nil?)
        logger.debug("[ObjectsCount][incrementObjectsCount] No object found in objects_count with object_uid = #{object_uid}, object will be created")
        obj = createCount(object_type, getCustomObjectId(object_type,object_uid))
        if(obj.nil?)
          raise("There is no object with object_uid = #{object_uid} and object = #{object_type} !!")
        end
      end
      logger.debug("[ObjectsCount][incrementObjectsCount] increment objects count BY #{objects_count} for object #{object_type} and object_uid = #{object_uid} ")
      
      case count_type
        when ENUM_NOTICE
        obj.notices_count += objects_count;
        if(state==1 and (object_type == ENUM_TAG or object_type == ENUM_COMMUNITY_USER))
          obj.notices_count_public +=objects_count 
        end
        when ENUM_LIST
        obj.lists_count += objects_count;         
        if(state==1) 
          obj.lists_count_public +=objects_count 
        end 
        when ENUM_COMMENT      
        if(object_type != ENUM_COMMENT)
          obj.comments_count += objects_count;
          if(state==1)
            obj.comments_count_public += objects_count;
          end
        end
        when ENUM_SUBSCRIPTION
        obj.subscriptions_count += objects_count;
        # create notices_check line
        if(object_type == ENUM_NOTICE)
          nc = NoticesCheck.getNotice(object_uid)
          if(nc.nil?)
            NoticesCheck.addNotice(object_uid)
          end
        end
        when ENUM_TAG
        obj.tags_count += objects_count;          
        if(state==1)
          obj.tags_count_public +=objects_count 
        end
      end
      
      obj.save
    rescue => e
      logger.error("[ObjectsCount][IncrementObjectsCount] Error : " + e.message)
      raise e
    end
  end
  
  
  # Method decrementObjectsCount (object : LIST or NOTICE) (count_type : LIST or NOTICE or SUBSCRIPTION or TAG or COMMENT)
  def self.decrementObjectsCount(object_type, object_uid, count_type, objects_count, state=0)
    begin
      logger.debug("[ObjectsCount][decrementObjectsCount] search for object = #{object_type} and object_uid = #{getCustomObjectId(object_type,object_uid)} in objects_count ")
      obj = ObjectsCount.find(:first, :conditions => " object_type = #{object_type} and object_uid = '#{getCustomObjectId(object_type,object_uid)}' ");
      if(obj.nil?)
        raise("[ObjectsCount][decrementObjectsCount] No object found with object_uid = #{object_uid} ")
      end
      logger.debug("[ObjectsCount][decrementObjectsCount] decrement objects count BY #{objects_count} for object #{object_type} and object_uid = #{object_uid} ")
      
      case count_type
        when ENUM_NOTICE:         
        obj.notices_count -= objects_count;       
        if(obj.notices_count < 0) 
          obj.notices_count = 0 
        end
        if(state==1 and (object_type == ENUM_TAG or object_type == ENUM_COMMUNITY_USER)) 
          obj.notices_count_public -=objects_count; 
          if(obj.notices_count_public < 0) 
            obj.notices_count_public = 0 
          end
        end
        when ENUM_LIST:           
        obj.lists_count -= objects_count;         
        if(obj.lists_count < 0)
          obj.lists_count = 0 
        end 
        if(state==1) 
          obj.lists_count_public -= objects_count; 
          if(obj.lists_count_public < 0) 
            obj.lists_count_public = 0 
          end
        end 
        when ENUM_COMMENT:
        if(object_type != ENUM_COMMENT)  
          obj.comments_count -= objects_count;
          if(state==1)
            obj.comments_count_public -= objects_count;
          end
          if(obj.comments_count < 0) 
            obj.comments_count = 0 
          end
          if(obj.comments_count_public < 0)
            obj.comments_count_public = 0
          end
        end
        when ENUM_SUBSCRIPTION:   
        obj.subscriptions_count -= objects_count; 
        if(obj.subscriptions_count < 0)
          obj.subscriptions_count = 0 
        end
        # delete notices_check line
        if(object_type == ENUM_NOTICE)
          if(obj.subscriptions_count == 0)
            NoticesCheck.deleteNotice(object_uid)
          end
        end
        when ENUM_TAG:            
        obj.tags_count -= objects_count;
        if(obj.tags_count < 0) 
          obj.tags_count = 0 
        end
        if(state==1)
          obj.tags_count_public -=objects_count;
          if(obj.tags_count_public < 0) 
            obj.tags_count_public = 0 
          end
        end      
      end
      
      obj.save
    rescue => e
      logger.error("[ObjectsCount][DecrementObjectsCount] Error : " + e.message)
      raise e
    end
  end  
  
  def self.updateObjectStatistics(object_type, object_uid, note)
    begin
      logger.debug("[ObjectsCount][updateObjectStatistics] object = #{object_type} -- object_uid = #{object_uid} -- note = #{note} ")
      if(object_type == ENUM_NOTICE)
        doc_id, doc_collection_id = UtilFormat.parseIdDoc(object_uid)
        obj = Notice.find(:first, :conditions => " doc_identifier = '#{doc_id}' and doc_collection_id = #{doc_collection_id} ");
        if(obj.nil?)
          raise("No notice with id : #{object_uid}");
        end
      elsif( object_type == ENUM_LIST )
        obj = List.find(:first, :conditions => " id = #{object_uid} ");
        if( obj.nil? )
          raise("No list with id : #{object_uid} ");
        end
      end
      
      obj.notes_avg = ( obj.notes_avg * obj.notes_count + note ) / (obj.notes_count + 1)
      obj.notes_count += 1;
      logger.debug("[ObjectsCount][updateObjectStatistics] object = #{object_type} -- object_uid = #{object_uid} -- notes_count = #{obj.notes_count} -- notes_avg = #{obj.notes_avg} ")
      obj.save;
    rescue => e
      logger.error("[ObjectsCount][UpdateObjectsStatistics] Error : " + e.message)
      raise e
    end
  end
  
  
  def self.getObjectCountById(object_type,object_uid)
    object_uid = object_uid.to_s.gsub(";",",")
    oc = ObjectsCount.find(:first, :conditions => " object_type = #{object_type} and object_uid = '#{object_uid}' ")
    return oc;
  end
  
  
  # Method updateCommentsCountPublic
  def self.updateCommentsCountPublic(oc, comments_count_public, new_state)
    if(new_state == COMMENT_PUBLIC)
      oc.comments_count_public += comments_count_public
    elsif(new_state == COMMENT_PRIVATE)
      oc.comments_count_public -= comments_count_public
    end
    oc.save
  end
  
  
  # Method updateListsCountPublic
  def self.updateListsCountPublic(oc, lists_count_public, new_state)
    if(new_state == LIST_PUBLIC)
      oc.lists_count_public += lists_count_public
    elsif(new_state == LIST_PRIVATE)
      oc.lists_count_public -= lists_count_public
    end
    oc.save
  end
  
  # Method updateTagsCountPublic
  def self.updateTagsCountPublic(oc, tags_count_public, new_state)
    if(new_state == TAG_PUBLIC)
      oc.tags_count_public += tags_count_public
    elsif(new_state == TAG_PRIVATE)
      oc.tags_count_public -= tags_count_public
    end
    oc.save    
  end
  
end