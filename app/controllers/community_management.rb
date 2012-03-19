require 'net/smtp'

class CommunityManagement < CommunityController
  include ApplicationHelper
  
  def setInfosUser(infoUser)
    @info_user = infoUser
    @log_management = LogManagement.new
    @log_management.setInfosUser(@info_user)
  end
  
  
  # Method addCommentAndNote
  def addCommentAndNote(content,note,uuid,object_type,object_uid,title,parent_id,state,workflow_comment_validation)
    Comment.transaction do
      begin
        child_state = state
        # Test for multiple comments
        first_comment = Comment.getCommentByUserAndObject(object_type, object_uid, uuid)
        if( !first_comment.nil? and MULTIPLE_COMMENTS == 0 )
          raise("No multiple comments !! This user has yet commented the object !!");
        end
        
        # Test for parent comment
        if( !parent_id.nil? and parent_id != 0 )
          parent_comment = Comment.getCommentById(parent_id);
          if(parent_comment.nil?)
            raise("No parent comment with id #{parent_id}");
          end
          if(parent_comment.state == COMMENT_PRIVATE)
            raise("Can't add child comment in private comment !!")
          end
          # Set child comment's state = parent comment's state
          child_state = parent_comment.state
          if(parent_comment.parent_id != 0 and !parent_comment.parent_id.nil? )
            raise("Multiple levels not authorized !!")
          end
        end
        
        # Comment for a notice
        if( object_type == ENUM_NOTICE )      
          # Verify that the document exists
          if copyNotice(object_uid)
            doc_identifier,doc_collection_id = UtilFormat.parseIdDoc(object_uid);
            if doc_identifier.blank? or doc_collection_id.blank?
              raise("Id notice blank #{object_uid}");
            end
            
            object_uid = doc_identifier + ";" + doc_collection_id
          else
            logger.error("[CommunityManagement] doc not found");
            raise("Id notice blank #{object_uid}");
          end
        end
        
        # Comment for a list
        if( object_type == ENUM_LIST )       
          # Verify that the list exists
          if( !List.exists?(object_uid) )
            logger.error("[CommunityManagement] list not found");
            raise("Id list blank #{object_uid}");
          end
        end        
        
        # If note was mentioned => addNote and update average note for object_uid
        note_id = 0
        if ( !note.nil? )
          item = Note.addNote(note,uuid,object_type,object_uid)
          note_id = item.id
        end
        
        # if content was mentioned => addComment and update comments count for object and user
        if( !content.nil? )
          item = Comment.addComment(content,uuid,object_type,object_uid,title,parent_id,child_state,note_id);
          logger.debug("[CommunityManagement] [addCommentAndNote] workflow_comment_validation : #{workflow_comment_validation}")
          if (workflow_comment_validation == 0)
            logger.debug("[CommunityManagement] [addCommentAndNote] validate comment : #{item.id}")
            workflow_manager = nil
            self.validateComment([item.id],workflow_manager);
          end  
        end
        
        return item;
      rescue => e
        logger.error("[CommunityManagement] addCommentAndNote : #{e.message}")
        raise e
      end
    end
  end
  
  
  # Method validateComment
  def validateComment(comments_id,workflow_manager)
    logger.debug("[CommunityManagement][validateComment] comments_id : #{comments_id.inspect} manager: #{workflow_manager}")
    begin
      # Validating comments
      Comment.validateComment(comments_id,workflow_manager);
    rescue => e
      logger.error("[CommunityManagement] validateComment : #{e.message}");
      raise e;
    end
  end
  
  
  # Method DeleteComment
  def deleteComment(comments_id)
    Comment.transaction do
      begin
        ids = comments_id.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")     # Preparing the sequence id in ('','','',''...)
        # Deleting comments
        Comment.deleteComment(comments_id);
        return true
      rescue => e
        logger.error("[CommunityManagement] deleteComment : #{e.message}");
        raise e;
      end
      return false
    end
  end
  
  def deleteAllUserComment(uuid)
    Comment.transaction do
      begin
        # Deleting comments
        Comment.deleteAllUserComment(uuid);
        return true
      rescue => e
        logger.error("[CommunityManagement] deleteAllUserComment : #{e.message}");
        raise e;
      end
      return false
    end
  end
  
  
  # Method changeCommentState
  def changeCommentState(comment_id, new_state)
    Comment.transaction do
      begin
        comment = Comment.getCommentById(comment_id)
        if(comment.nil?)
          raise("No comment with id = #{comment_id} ")
        end
        if(!comment.parent_id.nil? and comment.parent_id > 0)
          raise("Can not change state of child comment !!")
        end
        # Update if only old state != new state
        if(comment.state != new_state)
          # Update state for all comment children
          comments_children = Comment.getCommentsChildren(comment_id)
          comments_children.each do |child|
            # Increment/Decrement comment count public for user (comment + children)
            oc = ObjectsCount.getObjectCountById(ENUM_COMMUNITY_USER, child.uuid)
            ObjectsCount.updateCommentsCountPublic(oc, 1, new_state)
            Comment.changeCommentState(child, new_state)
          end
          logger.debug("[CommunityManagement][changeCommentState] update statistics, new_state = #{new_state} ")
          # Increment/Decrement comment count public for user            
          oc = ObjectsCount.getObjectCountById(ENUM_COMMUNITY_USER, comment.uuid)
          ObjectsCount.updateCommentsCountPublic(oc, 1, new_state)
          
          # Increment/Decrement comment count public for object (comment + children)
          oc = ObjectsCount.getObjectCountById(comment.object_type, comment.object_uid)
          ObjectsCount.updateCommentsCountPublic(oc, 1 + comments_children.size, new_state)
          
          # Increment/Decrement comment count for comment
          if(comments_children.size != 0)
            oc = ObjectsCount.getObjectCountById(ENUM_COMMENT, comment.id)
            ObjectsCount.updateCommentsCountPublic(oc, comments_children.size, new_state)
          end
          
        end
        comment = Comment.changeCommentState(comment, new_state)
        
        return comment
      rescue => e
        logger.error("[CommunityManagement][changeCommentState] Error : " + e.message)
        raise e
      end
    end  
  end
  
  
  # Method addCommentUserEvaluation
  def addCommentUserEvaluation(uuid, comment_id, comment_relevance)
    logger.debug("[CommunityManagement][addCommentUserEvaluation] uuid = #{uuid} # comment_id = #{comment_id} # comment_relevance = #{comment_relevance}")
    CommentUserEvaluation.transaction do
      begin
        community_user = CommunityUsers.getCommunityUserByUuid(uuid)
        if(community_user.nil?)
          raise("No community_user with uuid = #{uuid}")
        end
        comment = Comment.getCommentById(comment_id);
        if (comment.nil?)
          raise("No comment with id : #{comment_id} !!")
        end
        
        com_user_eval = CommentUserEvaluation.getCommentUserEvaluation(comment_id, uuid)
        
        
        if(!com_user_eval.nil?)
          if (com_user_eval.comment_relevance == comment_relevance)
            return {:comment => nil, :status => "ALREADY_EVALUATE"}
          else
            change = 1
          end
          # Update evaluation
          comment = CommentUserEvaluation.updateCommentUserEvaluation(comment, com_user_eval, comment_relevance)
          return {:comment => comment, :status => "CHANGE_VOTE"}
        else
          # Add new comment user evaluation
          comment = CommentUserEvaluation.addCommentUserEvaluation(uuid, comment, comment_relevance)
          return {:comment => nil, :status => "NEW"}
        end
        return comment, ""
      rescue => e
        logger.error("[CommunityManagement] addCommentUserEvaluation");
        raise e;
      end
    end
  end
  
  # Method listComments
  #   params :
  #     object, object_uid, uuid, note, user_type, comment_max, page, sort, direction
  #       all params are optional but at least one of object, object_uid, uuid, note or user_type must be mentioned
  def listCommentsAlerts()
    begin
      logger.debug("[CommunityManagement][listCommentsAlerts] Get only public comments")    
      commentsAlerts = Comment.getCommentsAlerts()
      
      return commentsAlerts
    rescue => e
      logger.error("[CommunityManagement] listCommentsAlerts");
      raise e;
    end  
  end
  
  
  # Method listComments
  #   params :
  #     object, object_uid, uuid, note, user_type, comment_max, page, sort, direction
  #       all params are optional but at least one of object, object_uid, uuid, note or user_type must be mentioned
  def listComments(object_type, object_uid, uuid, note, user_type, workflow, comment_max, page, sort, direction)
    begin
      limit = (comment_max == nil) ? DEFAULT_MAX_COMMENT : comment_max;
      offset = (page == nil) ? DEFAULT_PAGE_NUMBER_COMMENT*DEFAULT_MAX_COMMENT : (page.to_i-1)*limit.to_i;
      
      if(!object_type.nil? and !object_uid.nil? and object_type == ENUM_NOTICE)
        doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(object_uid);
        if doc_identifier.blank? or doc_collection_id.blank?
          raise("Id notice blank #{object_uid}");
        end
        object_uid = doc_identifier + ";" + doc_collection_id
      end
      
      if(@info_user.nil?)
        logger.debug("[CommunityManagement][listComments] @infos_user is nil")
      end
      
      state = nil
      user_id = nil
      
      if(!uuid.nil?)
        user_id = uuid
      elsif (INFOS_USER_CONTROL and !@info_user.nil?)
        user_id = @info_user.uuid_user  
      end
      
      if (user_id.nil?)
        state = COMMENT_PUBLIC
      end
      
      logger.debug("[CommunityManagement][listComments] uuid : #{uuid}")
      if(INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user != uuid)
        logger.debug("[CommunityManagement][listComments] uuid : #{uuid} and @info_user.uuid_user : #{@info_user.uuid_user}")
        logger.debug("[CommunityManagement][listComments] Get only public comments")
        state = COMMENT_PUBLIC
      end
      comments = Comment.getComments(object_type, object_uid, user_id, note, user_type, state, workflow, limit, offset, sort, direction)
      return comments
    rescue => e
      logger.error("[CommunityManagement] listComments");
      raise e;
    end  
  end
  
  def getOneComment(object_uid, workflow)
    begin
      if(@info_user.nil?)
        logger.debug("[CommunityManagement][getOneComment] @infos_user is nil")
      end

      comments = Comment.getOneComment(object_uid, workflow)
      return comments
    rescue => e
      logger.error("[CommunityManagement] getOneComment");
      raise e;
    end
  end
  
  # Method getRandomNotices
  def getRandomNotices(doc_id,max_notices)
    begin
      return ListUserRecord.getRandomNotices(doc_id,max_notices);
    rescue => e
      logger.error("[CommunityManagement] getRandomNotices");
      raise e;
    end
  end
  
  
  #  Method addTagToObject
  def addTagToObject(uuid, label, object_type, object_uid, tag_state, tag_workflow) 
    Tag.transaction do 
      begin
        cu = CommunityUsers.getCommunityUserByUuid(uuid)
        if(cu.nil?)
          raise("No community user with uuid = #{uuid} ")
        end
        
        if (object_type == ENUM_NOTICE)
          # object = notice 
          if copyNotice(object_uid) 
            doc_identifier,doc_collection_id = UtilFormat.parseIdDoc(object_uid);
            # object_uid = doc_id
            if doc_identifier.blank? or doc_collection_id.blank?
              raise("Id Notice blank : #{object_uid}"); 
            end
          else
            raise("No document with id = #{object_uid}");
          end  
        end   
        
        #  Get the object (notice or list) by object_uid;
        o_object = nil
        # Test if object_uid exists in lists or notices
        o_object =  (object_type == ENUM_NOTICE ) ? Notice.getNoticeByDocId(object_uid) :  List.getListById(object_uid);
        if(o_object.nil?)
          raise("No object with object_uid : #{object_uid} ")
        end
        
        tag = Tag.getTagByLabel?(label)
        if tag.nil?
          # if it don't exist, create
          tag = Tag.createTag(label)
        end
        # Verify label's existence in one notice
        if ObjectsTag.existTagForObject?(tag, object_type, object_uid, uuid) > 0
          # if exist, do nothing
          raise "User tagged this object yet !!"
        else
          # if it doesn't exist, create
          objecttag = ObjectsTag.addObjectTag(tag, uuid, object_type, object_uid, tag_state, tag_workflow)
          
          return objecttag;   
        end        
      end
    end
  end
  
  
  # Method deleteTagById
  def deleteTagById(id)
    begin
      Tag.deleteTagById(id);
      return true;
    rescue => e
      logger.error("[CommunityManagement][deleteTagById] Error : " + e.message)
      raise e
    end
    return     
  end
  
  
  # Method tagsAutoComplete
  #  Parmeters :
  #  label            : required
  def tagsAutoComplete(label)
    label = UtilFormat.remove_accents(label)
    return  Tag.tagsAutoComplete(label); 
  end
  
  
  # Method addCommunityUsers
  #  Parmeters :
  #    uuid            : required
  #    name            : required
  #    user_type       : optional
  def addCommunityUsers(uuid,name,user_type)
    cu = CommunityUsers.getCommunityUserByUuid(uuid)
    if(cu.nil?)
      u = CommunityUsers.addCommunityUsers(uuid,name,user_type);
      return u
    else
      raise("User with uuid = #{uuid} exists yet !!")
    end
  end
  
  
  # Method DeleteCommunityUsers
  #  Parmeters :
  #    id : required
  def deleteCommunityUsers(uuid)
    cu = CommunityUsers.getCommunityUserByUuid(uuid)
    if(cu.nil?)
      raise("There is no user with uuid = #{uuid} ")
    else
      CommunityUsers.deleteCommunityUsers(uuid);
      return true;
    end
  end
  
  
  def mergeRecordWithNotices(records)
    if records.nil? or records.empty?
      return records
    end
    records.each do | r |
      notice = Notice.getNoticeByDocId(r.id)
      if !notice.nil?
        uuid = nil
        if INFOS_USER_CONTROL and !@info_user.nil? and !@info_user.uuid_user.blank?
          uuid = @info_user.uuid_user
        end
        
        r.notice = FactoryNotice.createNotice(notice, nil, uuid)
        
        logger.debug("[community_management][mergeRecordWithNotices] notice #{notice.inspect}")
        logger.debug("[community_management][mergeRecordWithNotices] record #{r.inspect}")
        #        if (r.ptitle.empty?)
        #            logger.debug("[community_management][mergeRecordWithNotices] ptitle #{notice.dc_title}")
        #            r.ptitle = notice.dc_title;
        #        end
        #        if (r.atitle.empty?)
        #          r.atitle = notice.dc_title;
        #        end
        #        if (r.title.empty?)
        #          r.title = notice.dc_title;
        #        end
        #        if (r.author.empty?)
        #          r.author = notice.dc_author;
        #        end
        #        if (r.material_type.empty?)
        #          r.material_type = notice.dc_type;
        #        end
        #        if (r.material_type.empty?)
        #          r.material_type = notice.dc_type;
        #        end
      end
    end
    
    return records
  end
  
  
  # Method addCommentsAlert
  def addCommentsAlert(comment_id, uuid, message)
    CommentsAlert.transaction do
      begin
        cu = CommunityUsers.getCommunityUserByUuid(uuid)
        if(cu.nil?)
          raise("No community_user with uuid = #{uuid} ")
        end
        comment = Comment.getCommentById(comment_id);
        if (comment.nil?)
          raise("No comment with id : #{comment_id} !!")
        end
        
        ca = CommentsAlert.addCommentsAlert(comment_id, uuid, message)
        
        # Send mail to library find administrator
        subject = translate("SUBJECT_COMMENT_ALERT", nil, nil, "mail")
        message = translate("BODY_COMMENT_ALERT", ["#{cu.uuid} - #{cu.name}", comment.content, message], nil, "mail")
        Emailer.generateMail(LIBRARYFIND_EMAIL_USER, subject, message)
        return ca
      rescue => e
        logger.error("[CommunityManagement][addCommentsAlert] Error : " + e.message);
        raise e;
      end
    end
  end
  
  
  # Method deleteCommentsAlerts
  def deleteCommentsAlerts(comments_ids,uuids)
    CommentsAlert.transaction do
      begin
        if(comments_ids.size != uuids.size)
          raise("comments_ids size not equals uuids size - some informations miss")
        end
        cnt_com_id = 0
        comments_ids.each do |comment_id|
          logger.debug("[CommunityManagement][deleteCommentsAlerts] delete comment_id = #{comment_id} and uuid = #{uuids[cnt_com_id]}")
          ca = CommentsAlert.getCommentsAlert(comment_id, uuids[cnt_com_id])
          if(ca.nil?)
            logger.warn("[CommunityManagement][deleteCommentsAlerts] No alert sent by uuid = #{uuids[cnt_com_id]} on comment_id = #{comment_id} ")
          else
            CommentsAlert.deleteCommentsAlert(comment_id, uuids[cnt_com_id])
          end
          cnt_com_id += 1
        end
      end
    end
    return true
  end
  
  
  # Method updateProfileDescription
  def updateProfileDescription(uuid, description)
    begin
      community_user = CommunityUsers.getCommunityUserByUuid(uuid)
      if(community_user.nil?)
        raise("No user with uuid : #{uuid} !!")
      end
      
      # Update only if new description != old description
      if(description != community_user.description)
        community_user = CommunityUsers.updateProfileDescription(community_user, description)
      end
      return community_user
    rescue => e
      logger.error("[CommunityManagement][updateProfileDescription] Error : " + e.message);
      raise e;
    end
  end
  
  
  # Method getTagWithDetails
  #   params :
  #     tag_id : Integer
  #   returns :
  #     id              : Integer
  #     label           : String
  #     lists_count     : Integer (Count lists tagged public by this tag, + private references of authenticated user)       
  #     simple_lists    : Array (id, title, ptitle, state, description)
  #     notices_count   : Integer (Count notices tagged public by this tag, + private references of authenticated user)  
  #     simple_notices  : Array (identifier, dc_title)
  def getTagWithDetails(tag_id, logs)
    # Get tag from table Tags
    tag = Tag.getTagById(tag_id);
    if(tag.nil?)
      raise("No tag with id = #{tag_id}");
    end
    
    # Get all public objects_tags by tag_id and private objects_tags referenced by user authenticated
    uuid = nil
    if INFOS_USER_CONTROL and !@info_user.nil? and !@info_user.uuid_user.blank?
      uuid = @info_user.uuid_user
    end
    objects = ObjectsTag.getObjectsTagByTagId(tag_id, uuid)
    
    object_tag_struct = nil
    simple_notices = []
    simple_lists = []
    
    detailed_list = false
    
    tag_weight = 0
    
    objects.each do |obj|
      tag_weight += 1
      if(obj.object_type == ENUM_NOTICE)
        notice = Notice.getNoticeByDocId(obj.object_uid)
        simple_notices << FactoryNotice.createSimpleNotice(notice)
      elsif(obj.object_type == ENUM_LIST)
        list = List.getListByUserAndState(obj.object_uid.to_i, uuid)
        
        if (!list.nil?)
          community_user = CommunityUsers.getCommunityUserByUuid(list.uuid)
          simple_lists << FactoryList.createList(list, community_user, uuid, detailed_list)
        end
        
      end
    end
    
    @log_management.logs(logs)
    
    return FactoryTag.createTag(tag, tag_weight, object_tag_struct, simple_lists.size, simple_notices.size, simple_lists, simple_notices);
  end
  
  
  # Method getTagsByUserWithDetails
  def getTagsByUserWithDetails(uuid, sort, direction, page, max)
    
    if (INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user == uuid)
      state_tag = nil
    else
      state_tag =  TAG_PUBLIC
    end
    limit = (max == nil) ? DEFAULT_MAX_TAG : max;
    offset = (page == nil) ? DEFAULT_PAGE_NUMBER_TAG*DEFAULT_MAX_TAG : (page.to_i-1)*limit.to_i;
    tags = Tag.getTagsByUser(uuid, state_tag, sort, direction, offset, limit);
    list_tags = []
    object_tag_struct = nil
    
    simple_lists = []
    simple_notices = []
    other_users_objects = []
    lists_count = 0
    notices_count = 0
    tags.each do |t|
      notices_count = Tag.getNoticesCountByUser(t,uuid,state_tag);
      lists_count = Tag.getListsCountByUser(t,uuid, state_tag);
      tag_weight = lists_count + notices_count
      list_tags << FactoryTag.createTag(t, tag_weight, object_tag_struct, lists_count, notices_count, simple_lists, simple_notices, other_users_objects)
    end
    return list_tags;
  end
  
  
  # Method getTagDetailsByUser
  #   description : There are differences between this method and getTagWithDetails (cf object_tag_struct)
  def getTagDetailsByUser(tag_id, uuid)
    
    # Get tag from table tags
    tag = Tag.getTagById(tag_id)
    if(tag.nil?)
      raise("There is no tag with tag_id = #{tag_id} ")
    end
    
    if (INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user == uuid)
      state_tag = nil
    else
      state_tag =  TAG_PUBLIC
    end
    
    # Get objects tagged by user with this tag
    objects = ObjectsTag.getObjectsByTagAndUser(tag_id, uuid, state_tag);
    
    simple_notices = []
    simple_lists = []
    detailed_list = false
    community_user = CommunityUsers.getCommunityUserByUuid(uuid)
    
    objects.each do |obj|
      object_tag_struct = FactoryObjectTag.createObjectTag(obj, community_user)
      if(obj.object_type == ENUM_NOTICE)
        notice = Notice.getNoticeByDocId(obj.object_uid)
        simple_notices << FactoryNotice.createSimpleNotice(notice, object_tag_struct)
      elsif(obj.object_type == ENUM_LIST)
        list = List.getListById(obj.object_uid.to_i)
        community_user = CommunityUsers.getCommunityUserByUuid(list.uuid)
        simple_lists << FactoryList.createList(list, community_user, uuid, detailed_list, object_tag_struct)
      end
    end
    
    other_objects = ObjectsTag.getOtherUsersObjectsByTag(tag_id, uuid)
    other_users_objects = []
    title = ""
    other_objects.each do |obj_tag|
      if(obj_tag.object_type == ENUM_NOTICE)
        title = obj_tag.dc_title
      else
        title = obj_tag.title
      end
      community_user = CommunityUsers.getCommunityUserByUuid(obj_tag.uuid) 
      other_users_objects << FactoryObjectTag.createObjectTag(obj_tag, community_user, title)
    end
    
    tag_weight = 0
    object_tag_struct = nil
    return FactoryTag.createTag(tag, tag_weight, object_tag_struct, simple_lists.size, simple_notices.size, simple_lists, simple_notices, other_users_objects)
    
  end
  
  
  # Method getTagsByObject
  def getTagsByObject(object_type, object_uid, uuid, sort, direction,  page, max)
    
    if(INFOS_USER_CONTROL and !@info_user.nil?)
      uuid =  @info_user.uuid_user
    end
    
    limit = (max == nil) ? DEFAULT_MAX_TAG : max;
    offset = (page == nil) ? DEFAULT_PAGE_NUMBER_TAG*DEFAULT_MAX_TAG : (page.to_i-1)*limit.to_i;    
    
    tags = Tag.getTagsByObject(object_type, object_uid, uuid, sort, direction, offset, limit)
    
    list_tags = []
    community_user = CommunityUsers.getCommunityUserByUuid(uuid)
    #    if(community_user.nil?)
    #      raise("There is no user with uuid = #{uuid} !!")
    #    end
    sum = 0
    tags.each do |t|
      objTag = ObjectsTag.getObjectsTagByObjectAndTagAndUser(t.id, object_type, object_uid, uuid)
      object_tag_struct = FactoryObjectTag.createObjectTag(objTag, community_user)
      list_tags << FactoryTag.createTag(t, t.tag_weight, object_tag_struct)
      sum += t.tag_weight.to_i
    end
    
    return {:tags => list_tags, :sum_weight => sum };
  end
  
  def deleteUserReferencesTags(tags_ids, uuid)
    cu = CommunityUsers.getCommunityUserByUuid(uuid)
    if( cu.nil?  )
      raise("No user with uuid = #{uuid} ")
    end
    if(INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user == uuid)
      ObjectsTag.transaction do
        begin
          tags_ids.each do |tag_id|
            ObjectsTag.deleteUserReferencesTag(tag_id, uuid)
          end
        end
      end
      return true;
    else
      raise("User does not have permissions to delete these references !!")
      return false
    end
  end
  
  
  
  # Method changeObjectTagState
  def changeObjectTagState(object_tag_id, new_state)
    objTag = ObjectsTag.getObjectTagById(object_tag_id);
    if(objTag.nil?)
      raise("There is no object to update !! You must verify parameters !!");
    end
    if(objTag.state != new_state)
      ObjectsTag.transaction do
        # increment objects_tags count for user
        oc = ObjectsCount.getObjectCountById(ENUM_COMMUNITY_USER, objTag.uuid)
        ObjectsCount.updateTagsCountPublic(oc, 1, new_state)
        
        # increment objects_tags count for object
        oc = ObjectsCount.getObjectCountById(objTag.object_type, objTag.object_uid)
        ObjectsCount.updateTagsCountPublic(oc, 1, new_state)
        
        # create count for tag
        oc = ObjectsCount.getObjectCountById(ENUM_TAG, objTag.tag_id)
        if(oc.nil?)
          ObjectsCount.createCount(ENUM_TAG, objTag.tag_id)
        end
        
        objTag = ObjectsTag.changeObjectTagState(objTag, new_state)
      end
      
    end
    
    return objTag
  end
  
  
  # Method changeReferencedTagsState
  def changeReferencedTagsState(tags_ids, new_state, uuid)
    ObjectsTag.transaction do
      if (INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user == uuid)
        state_tag = nil
      else
        state_tag =  TAG_PUBLIC
      end
      
      tags_ids.each do |tag_id|
        tag = Tag.getTagById(tag_id)
        if(tag.nil?)
          logger.warn("No tag with tag_id = #{tag_id} !!")
        else
          objects_tags = ObjectsTag.getObjectsByTagAndUser(tag_id, uuid, state_tag)
          objects_tags.each do |ot|
            if(!ot.nil?)
              changeObjectTagState(ot.id, new_state)
            end
          end
        end
      end
    end  
  end
  
  # Method deleteObjectTagReference
  def deleteObjectTagReference(object_tag_id)
    begin
      objTag = ObjectsTag.getObjectTagById(object_tag_id)
      if(objTag.nil?)
        raise("No object_tag with id = #{object_tag_id}");
      end
      if(INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user == objTag.uuid)
        ObjectsTag.transaction do
          ObjectsTag.deleteObjectTagReference(object_tag_id)
        end
        return true 
      else
        raise("User does not have permission to delete this reference !!")
        return false
      end
    rescue => e
      logger.error("[CommunityManagement][deleteObjecTagReference] Error : #{e.message}")
    end
  end
  
  
  def getCommentsByNote(object_uid, note)
    logger.debug("[CommunityManagement] getCommentsByNote : object_uid: #{object_uid} note: #{note}")
    return Comment.getCommentsListByNote(object_uid, note)
  end
  
  
  def getMostPertinentComment(object_uid)
    logger.debug("[CommunityManagement] getMostPertinentComment : object_uid: #{object_uid}")
    return Comment.getMostPertinentComment(object_uid)
  end
  
  def getUserByIdentifier(identifier)
    logger.debug("[CommunityManagement] getUserByIdentifier : identifier #{identifier}")
    if identifier.nil?
      return nil
    end
    user = CommunityUsers.getCommunityUserByIdentifier(identifier)
    
    if (!user.nil?)
      return user.uuid
    else
      return nil
    end
  end
  
end
