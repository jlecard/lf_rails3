  # Atos Origin France - 
  # Tour Manhattan - La Défense (92)
  # roger.essoh@atosorigin.com
  
  class ObjectsTag < ActiveRecord::Base
    belongs_to :notice 
    belongs_to :tag, :foreign_key => :tag_id
    belongs_to :list
    belongs_to :community_users, :foreign_key => :uuid
    
    
    
    after_create { |objectTag|
      # Increment statistics only if WORKFLOW_TAG_VALIDATION = 1 
      if(objectTag.workflow == TAG_VALIDATED)
        # increment objects_tags count for user
        # si nouveau tag pour l'utilisateur
        ref_tag_user = ObjectsTag.getObjectsByTagAndUser(objectTag.tag_id, objectTag.uuid)
        if (!ref_tag_user.nil? and !ref_tag_user.empty? and ref_tag_user.size == 1)
          ObjectsCount.incrementObjectsCount(ENUM_COMMUNITY_USER, objectTag.uuid, ENUM_TAG, 1, objectTag.state)
        end
        # increment objects_tags count for object
        ObjectsCount.incrementObjectsCount(objectTag.object_type, objectTag.object_uid, ENUM_TAG,1,objectTag.state)
        # create count for tag
        ObjectsCount.createCount(ENUM_TAG, objectTag.tag_id) 
        # increment objects count for objectTag
        if (objectTag.object_type == ENUM_LIST)
          list_state = List.getListById(objectTag.object_uid)
          if (!list_state.nil?)
            ObjectsCount.incrementObjectsCount(ENUM_TAG, objectTag.tag_id, objectTag.object_type, 1, list_state)  
          end
        else
          ObjectsCount.incrementObjectsCount(ENUM_TAG, objectTag.tag_id, objectTag.object_type, 1, objectTag.state)  
        end
        
        log_management = LogManagement.new()
        log_management.addLogTag(objectTag.tag, objectTag.object_uid, objectTag.object_type, 1)
      end
    }
    
    after_destroy { |objectTag|
      begin
      if(objectTag.workflow == 1)
        # decrement objects_tags count for user
        ref_tag_user = ObjectsTag.getObjectsByTagAndUser(objectTag.tag_id, objectTag.uuid)
        if (ref_tag_user.nil? or ref_tag_user.empty?) 
          ObjectsCount.decrementObjectsCount(ENUM_COMMUNITY_USER, objectTag.uuid, ENUM_TAG, 1, objectTag.state)
        end
        # decrement objects_tags count for object
        ObjectsCount.decrementObjectsCount(objectTag.object_type, objectTag.object_uid, ENUM_TAG,1,objectTag.state)
        # decrement objects count for objectTag
        ObjectsCount.decrementObjectsCount(ENUM_TAG, objectTag.tag_id, objectTag.object_type, 1, objectTag.state)  
      
        log_management = LogManagement.new()
        log_management.addLogTag(objectTag.tag, objectTag.object_uid, objectTag.object_type, 0)
      end
    rescue => e
      logger.errro("[ObjectsTag][after_destory] Error : " + e.message)
      raise e
      end
    }
    
    after_update{ |objectTag|
      logger.info("[ObjectsTag][after_update] #{objectTag.tag_id} ")
    }
    
    
    #check one tag in one object
    def self.existTagForObject?(tag, object_type, object_uid, uuid)
      if tag.nil?
        raise "Tag nil !!"
      end
      result = ObjectsTag.find(:first, :conditions => " object_type = #{object_type} and object_uid = '#{object_uid}' and tag_id = #{tag.id} and uuid = '#{uuid}' ")
      if !result.nil?
        return result.id
      else
        return -1
      end
    end
    
    
    def self.getObjectTagById(id)
      return ObjectsTag.find(:first, :conditions => "id = #{id}" )
    end
    
    
    # Method addObjectTag ! not tag
    def self.addObjectTag(tag, uuid, object_type, object_uid,tag_state,tag_workflow)   
      if tag.nil?
        raise "Tag nil !!"
      end
      objectTag = ObjectsTag.new;
      objectTag.tag_date = DateTime::now();
      objectTag.uuid = uuid;
      objectTag.tag_id = tag.id;    
      objectTag.workflow = tag_workflow;
      objectTag.workflow_date = DateTime::now();
      objectTag.last_modified_date = DateTime::now();
      objectTag.object_type = object_type; 
      objectTag.object_uid = object_uid; 
      objectTag.state = tag_state;
      objectTag.save;
      
      return tag  
    end
    
    
    # Method changeState
    def self.changeState(tag,uuid,object_type,object_uid,state)
      begin
        
        object_tag = ObjectsTag.find_by_sql ["select objects_tags.id  from tags, objects_tags where objects_tags.tag_id = #{tag[0].id} AND objects_tags.object_type = 1 AND objects_tags.object_uid = #{object_uid} AND objects_tags.uuid = #{uuid}"];
        object_tag = ObjectsTag.update(object_tag[0], :state=> state);
        if object_tag.state=0
          ObjectsCount.decrementObjectsCount(object_tag.object_type, object_tag.object_uid, ENUM_TAG,1,object_tag.state)
          ObjectsCount.decrementObjectsCount(ENUM_TAG, object_tag.id, ENUM_TAG, 1)  
        elsif 
          ObjectsCount.incrementObjectsCount(object_tag.object_type, object_tag.object_uid, ENUM_TAG,1,object_tag.state)  
          ObjectsCount.incrementObjectsCount(ENUM_TAG, object_tag.id, ENUM_TAG, 1)  
        end
      end
    end
    
    
    # Returns all public objects_tags by tag_id and private objects_tags referenced by user authenticated 
    def self.getObjectsTagByTagId(tag_id, uuid = nil)
      # Get public objects_tags
      query = " SELECT DISTINCT(object_uid) as object_uid, object_type as object_type FROM  objects_tags WHERE (tag_id = #{tag_id} and state = #{TAG_PUBLIC}) "
      # Get objects_tags by user (private ones)
      if !uuid.nil? and !uuid.blank?
        query += " or (tag_id = #{tag_id} and uuid = '#{uuid}') "
      end
      objects = ObjectsTag.find_by_sql(query);
      return objects;
    end
    
    
    def self.getObjectsByTagAndUser(tag_id, uuid, tag_state=nil)
      conditions = " tag_id = #{tag_id} and uuid = '#{uuid}' "
      if (!tag_state.nil?)
        conditions += " and state = #{tag_state} "
      end
      objects = ObjectsTag.find(:all, :conditions => " #{conditions} ", :order => :object_type)
      
      return objects;
    end
    
    def self.getObjectsTagByObjectAndTagAndUser(tag_id, object_type, object_uid, uuid)
      return ObjectsTag.find(:first, :conditions => " tag_id = #{tag_id} and object_type = #{object_type} and object_uid = '#{object_uid}' and uuid = '#{uuid}' ")
    end
    
    def self.getCountReferencesByUser(tag_id, uuid, object_type)
      return ObjectsTag.count(:conditions => " tag_id = #{tag_id} and uuid = '#{uuid}' and object_type = #{object_type} ")
    end
    
    
    # Method delete UserReferencesTag
    def self.deleteUserReferencesTag(tag_id, uuid)
      return ObjectsTag.destroy_all(" tag_id = #{tag_id} and uuid = '#{uuid}' ")
    end
    
    
    # Method getOtherUsersObjectsByTag 
    def self.getOtherUsersObjectsByTag(tag_id,uuid)
      query = "select o.id, o.object_type, o.tag_date, o.object_uid, o.uuid, o.state, o.tag_id, n.dc_title, l.title from objects_tags o LEFT JOIN notices n ON o.object_uid = CONCAT(n.doc_identifier,CONCAT(';',n.doc_collection_id)) LEFT JOIN lists l ON o.object_uid = l.id where o.tag_id = #{tag_id} AND o.uuid NOT LIKE '#{uuid}' AND o.state = 1 order by o.tag_date DESC "
      
      objects = ObjectsTag.find_by_sql(query)
      
      return objects
    end
    
    
    # Method changeObjectTagState
    def self.changeObjectTagState(objTag, new_state)
      objTag.state = new_state;
      objTag.save
      return objTag
    end
    
    
    def self.deleteObjectTagReference(object_tag_id)
      ObjectsTag.destroy_all(" id = #{object_tag_id} ")
    end
    
    
  end
