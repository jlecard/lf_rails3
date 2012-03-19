

class CommunityDispatch < DispatchAbstract
  
  ##################################################################################################################
  ##                                                                                                              ##
  ##                                             Default                                                          ##
  ##                                                                                                              ##
  ##################################################################################################################
  def driver
    logger.debug("LibraryFind: " + ::LIBRARYFIND_WSDL.to_s)
    
    case LIBRARYFIND_WSDL
      when LIBRARYFIND_WSDL_ENGINE
      require 'soap/wsdlDriver'
      driver = SOAP::WSDLDriverFactory.new(LIBRARYFIND_WSDL_HOST).create_rpc_driver
      return driver
    else
      m = CommunityManagement.new()
      m.setInfosUser(@info_users)
      return m
    end
  end
  
  
  def addCommentAndNote(content,note,uuid,object,object_id,title,parent_id,state)
    objdriver = driver;
    objdriver.send :addCommentAndNote, content,note,uuid,object,object_id,title,parent_id,state,WORKFLOW_COMMENT_VALIDATION;
  end
  

  def validateComment(comments_id,workflow_manager)
    objdriver = driver;
    objdriver.send :validateComment, comments_id, workflow_manager;
  end
  
  
  def deleteComment(comments_id)
    objdriver = driver;
    objdriver.send :deleteComment, comments_id
  end
  
  def deleteAllUserComment(uuid)
    objdriver = driver;
    objdriver.send :deleteAllUserComment, uuid
  end
  
  def changeCommentState(comment_id, new_state)
    objdriver = driver
    objdriver.send :changeCommentState, comment_id, new_state
  end
  
  
  def addCommentUserEvaluation(uuid,comment_id,comment_relevance)
    objdriver = driver;
    objdriver.send :addCommentUserEvaluation,uuid,comment_id,comment_relevance;
  end
  
  def getRandomNotices(doc_id,max_notices)
    objdriver = driver;
    objdriver.send :getRandomNotices, doc_id,max_notices
  end
  
  
  def addTagToObject(uuid, label, object, object_id, tag_state)
    objdriver = driver;
    objdriver.send :addTagToObject, uuid, label, object, object_id, tag_state, TAG_VALIDATED;
  end
  
  
  def deleteTagById(id)
    objdriver = driver;
    objdriver.send :deleteTagById,id;
  end
  
  
  def tagsAutoComplete(label)
    objdriver = driver;
    objdriver.send :tagsAutoComplete,label;
  end
  
  
  def addCommunityUsers(uuid, name, user_type)
    objdriver = driver;
    objdriver.send :addCommunityUsers, uuid, name, user_type;
  end
  
  
  def deleteCommunityUsers(uuid)
    objdriver = driver;
    objdriver.send :deleteCommunityUsers, uuid;
  end
  
  
  def mergeRecordWithNotices(records)
    objdriver = driver;
    objdriver.send :mergeRecordWithNotices, records;
  end
  
  
  def addCommentsAlert(comment_id, uuid, message)
    objdriver = driver;
    objdriver.send :addCommentsAlert, comment_id, uuid, message;
  end  
  
  
  def deleteCommentsAlerts(comments_ids,uuids)
    objdriver = driver;
    objdriver.send :deleteCommentsAlerts, comments_ids,uuids;
  end
  
  
  def updateProfileDescription(uuid, description)
    objdriver = driver;
    objdriver.send :updateProfileDescription, uuid, description;
  end
  
  
  def getTagWithDetails(tag_id, logs = nil)
    objdriver = driver;
    objdriver.send :getTagWithDetails, tag_id, logs;
  end
  
  
  def getTagsByUserWithDetails(uuid, sort, direction, page, max)
    objdriver = driver;
    objdriver.send :getTagsByUserWithDetails, uuid, sort, direction, page, max;
  end
  
  
  def changeObjectTagState(object_tag_id, new_state)
    objdriver = driver;
    objdriver.send :changeObjectTagState, object_tag_id, new_state;
  end
  
    
  def changeReferencedTagsState(tags_ids, new_state, uuid)
    objdriver = driver
    objdriver.send :changeReferencedTagsState, tags_ids, new_state, uuid;
  end
  
  
  def getTagDetailsByUser(tag_id, uuid)
    objdriver = driver;
    objdriver.send :getTagDetailsByUser, tag_id, uuid;
  end
  
  
  def getTagsByObject(object, object_id, uuid, sort, direction, page, max)
    objdriver = driver;
    objdriver.send :getTagsByObject, object, object_id, uuid, sort, direction, page, max;
  end
  
  def deleteUserReferencesTags(tags_ids, uuid)
    objdriver = driver;
    objdriver.send :deleteUserReferencesTags, tags_ids, uuid;
  end
  
  
  def deleteObjectTagReference(object_tag_id)
    objdriver = driver;
    objdriver.send :deleteObjectTagReference, object_tag_id;
  end
  
  
  def getCommentsByNote(object, object_id, note)
    objdriver = driver
    objdriver.send :getCommentsByNote, object, object_id, note
  end
  
  def getMostPertinentComment(object_uid)
    objdriver = driver
    objdriver.send :getMostPertinentComment, object_uid
  end

  def listCommentsAlerts()
    objdriver = driver
    objdriver.send :listCommentsAlerts
  end

  def listComments(object, object_id, uuid, note, user_type, workflow, comment_max, page, sort, direction)
    objdriver = driver
    objdriver.send :listComments, object, object_id, uuid, note, user_type, workflow, comment_max, page, sort, direction
  end
  
  def getOneComment(object_uid, workflow)
    objdriver = driver
    objdriver.send :getOneComment, object_uid, workflow    
  end
  
  def getUserByIdentifier(identifier)
    objdriver = driver
    objdriver.send :getUserByIdentifier, identifier
  end
  
end