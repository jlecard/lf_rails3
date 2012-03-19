# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Innovation
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
class CommunityJsonController < JsonApplicationController

  include SearchHelper
  
  #  Method : AddCommentAndNote
  #  params :
  #    content      : required (optional if note is mentioned)
  #    note         : required (optional if content is mentioned)
  #    uuid         : required
  #    object_type       : required
  #    object_uid    : required
  #    title        : required (optional if note is mentioned)
  #    parent_id    : optional
  #    state        : optional (default => 0, if content is mentioned)
  #
  ## This method adds a new Comment or Note or both of them sent by user having id = uuid
  ## workflow is COMMENT_VALIDATED by default
  ## workflow_date is the workflow's modification date
  ## object_uid is the document's identifier having format doc_identifier_id;doc_collection_id
  def AddCommentAndNote
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      content = extract_param("content",String,nil);
      note = extract_param("note",Integer,nil);
      if( content.nil? and note.nil? )
        raise("Content or note is required !!");
      end
      
      uuid = extract_param("uuid",String,nil);
      if( uuid.nil? )
        raise("No uuid !!");
      end
      
      cu = CommunityUsers.getCommunityUserByUuid(uuid)
      if( cu.nil? )
        raise("No community user with uuid = #{uuid}")
      end
      
      object_type = extract_param("object_type",Integer,nil);
      if( object_type.nil? )
        raise("No object !!");
      end
      
      object_uid = extract_param("object_uid",String,nil);
      if( object_uid.nil? )
        raise("No object_uid !!");
      end
      
      parent_id = extract_param("parent_id", Integer, nil);
      
      title = extract_param("title", String, nil);
      
      state = extract_param("state",Integer, COMMENT_PRIVATE);
      
      if( !content.nil? )
        logger.debug("[CommunityJsonController][AddCommentAndNote] state verificiation")
        if( state.nil? )
          raise("No state !!")
        end
        state = state.to_i
      end
      
      results = $objCommunityDispatch.addCommentAndNote(content,note,uuid,object_type,object_uid,title,parent_id,state);
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][AddCommentAndNote] Error : " + e.message);
      logger.error("[CommunityJsonController][AddCommentAndNote] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddCommentAndNote " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method ValidateComment
  #   Parameters :
  #     comments_id :   required, is a table of comment identifiers, at least one comment's id required
  #     workflow_manager : required
  #
  ## This method updates comment's workflow to 1 (validated), sets the state manager 
  ## and updates the workflow date for all comments metioned in the table comments_id
  def ValidateComment
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      comments_id = extract_param("comments_id",Array,nil);
      if(comments_id.nil?)
        raise("No comments_id !! ");
      end
      
      workflow_manager = extract_param("state_manager",String,nil);
      if(workflow_manager.nil?)
        raise("No workflow_manager !! ");
      end
      
      results = $objCommunityDispatch.validateComment(comments_id,workflow_manager);
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][ValidateComment] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] ValidateComment " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method DeleteComment
  #   params :
  #     comments_id : required (Array of comment_id, at least one comment's id required)
  #
  ##  description : This method deletes all comments having identifier in the list comments_id
  def DeleteComment
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      comments_id = extract_param("comments_id",Array,nil);
      if(comments_id.nil?)
        raise("No comments_id !! ")  
      end
      results = $objCommunityDispatch.deleteComment(comments_id);
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][DeleteComment] Error : " + e.message);
      logger.error("[CommunityJsonController][DeleteComment] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] DeleteComment " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  def DeleteAllUserComment
    error = 0;
    results = nil;
    begin
      uuid = extract_param("uuid",String,nil);
      if(uuid.nil?)
        raise("No uuid !! ")  
      end
      results = $objCommunityDispatch.deleteAllUserComment(uuid);
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][deleteAllUserComment] Error : " + e.message);
      logger.error("[CommunityJsonController][deleteAllUserComment] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message  => msg
    }.to_json
  end
  
  
  # Method ChangeCommentState
  def ChangeCommentState
    error = 0;
    _sTime = Time.now().to_f
    results = nil;
    begin
      comment_id = extract_param("comment_id",String,nil);
      if(comment_id.nil?)
        raise("No comment_id !! ")  
      end
      new_state = extract_param("new_state",String, nil);
      if(new_state.nil?)
        raise("No new_state !!")
      end
      new_state = new_state.to_i
      if(new_state != COMMENT_PUBLIC and new_state != COMMENT_PRIVATE)
        raise("Invalid new_state #{new_state}, (Help : COMMENT_PUBLIC : #{COMMENT_PUBLIC} and COMMENT_PRIVATE : #{COMMENT_PRIVATE}) ")
      end
      
      results = $objCommunityDispatch.changeCommentState(comment_id, new_state);
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][changeCommentState] Error : " + e.message);
      logger.error("[CommunityJsonController][changeCommentState] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] ChangeCommentState " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method : AddCommentUserEvaluation
  #  params :
  #    uuid               : required
  #    comment_id         : required
  #    comment_relevance  : required
  def AddCommentUserEvaluation
    logger.debug("[CommunityJsonController][AddCommentUserEvaluation]")
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      uuid = extract_param("uuid",String,nil);
      if( uuid.nil? )
        raise("No uuid !!")
      end
      
      comment_id = extract_param("comment_id",Integer,nil);
      
      if( comment_id.nil? )
        raise("No comment_id !!");
      end
      
      comment_relevance = extract_param("comment_relevance",String,nil);
      if( comment_relevance.nil? )
        raise("No comment_relevance !!");
      end
      # Convert comment_relevance
      comment_relevance = comment_relevance.to_i
      if( comment_relevance != LIKE_COMMENT and comment_relevance != DONT_LIKE_COMMENT)
        raise("Invalid comment_relevance : #{comment_relevance} (Help : COMMENT_RELEVANT : #{LIKE_COMMENT} and COMMENT_NOT_RELEVANT = : #{DONT_LIKE_COMMENT}  ")
      end
      
      results = $objCommunityDispatch.addCommentUserEvaluation(uuid, comment_id, comment_relevance);
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][AddCommentUserEvaluation] Error : " + e.message);
      logger.error("[CommunityJsonController][AddCommentUserEvaluation] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddCommentUserEvaluation " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  def ListCommentsAlerts
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      results = $objCommunityDispatch.listCommentsAlerts();   
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][ListCommentsAlerts] Error : " + e.message);
      logger.error("[CommunityJsonController][ListCommentsAlerts] Backtrace : " + e.backtrace.join("\n"));      
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] ListCommentsAlerts " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  def ListComments
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      object_type = extract_param("object_type",Integer,nil);
      
      object_uid = extract_param("object_uid",String,nil);
      
      uuid = extract_param("uuid",String,nil);      

      note = extract_param("note",Integer,nil);
      
      user_type = extract_param("user_type",String,nil);
      
      if(object_type.nil? and object_uid.nil? and user_type.nil? and note.nil? and uuid.nil?)
        raise("At least one parameter must be mentioned (object_type and object_uid, user_type, note, uuid)")
      end
      
      workflow = extract_param("workflow", Integer, COMMENT_VALIDATED)
      comment_max = extract_param("comment_max",Integer,nil);
      page = extract_param("page",Integer,nil); 
      sort = extract_param("sort",String,SORT_DATE);
      direction = extract_param("direction",String,DIRECTION_UP);
      
      results = $objCommunityDispatch.listComments(object_type,object_uid,uuid,note,user_type,workflow,comment_max,page,sort,direction);
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][ListComments] Error : " + e.message);
      logger.error("[CommunityJsonController][ListComments] Backtrace : " + e.backtrace.join("\n"));      
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] ListComments " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  def GetOneComment
    error = 0;
    results = nil;
    begin 
      object_uid = extract_param("object_uid",String,nil);
      if(object_uid.nil?)
        raise("object_uid must be mentionned")
      end 
      workflow = extract_param("workflow", Integer, COMMENT_VALIDATED)
      
      results = $objCommunityDispatch.getOneComment(object_uid,workflow);
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][GetOneComment] Error : " + e.message);
      logger.error("[CommunityJsonController][GetOneComment] Backtrace : " + e.backtrace.join("\n"));      
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results => results,
      :error    => error,
      :message  => msg
    }.to_json
  end
  
  # Method GetRandomNotices
  def GetRandomNotices
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    msg = ""
    begin
      
      doc_id = extract_param("doc_id",String,nil);
      if( doc_id.nil? )
        raise("No doc_id !!");
      end
      
      max_notices = extract_param("max_notices",Integer,MAX_NOTICES);
      
      results = $objCommunityDispatch.getRandomNotices(doc_id,max_notices);
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][GetRandomNotices] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results => results,
      :error    => error,
      :message  => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetRandomNotices " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # AddTagToObject
  #   params :
  #     uuid :      required
  #     label:      required
  #     object_type :    required
  #     object_uid : required
  #     state :     optional (default => 0, private reference)
  def AddTagToObject
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      uuid = extract_param("uuid",String,nil);
      if( uuid.nil? )
        raise("No uuid !!");
      end
      
      label = extract_param("label",String,nil);
      if( label.nil? )
        raise("No label !!");
      end
      
      object_type = extract_param("object_type",Integer,nil);
      if( object_type.nil? )
        raise("No object !!");
      end
      
      object_uid = extract_param("object_uid",String, nil)
      object_uid = CGI::unescape(object_uid)
      if( object_uid.nil? )
        raise("No object_uid !!");
      end
      
      state = extract_param("state",Integer,0)
      if(!state.nil? and state != TAG_PRIVATE and state != TAG_PUBLIC)
        raise("Invalid state : #{state} (Help: TAG_PRIVATE : #{TAG_PRIVATE} and TAG_PUBLIC : #{TAG_PUBLIC} ")
      end
      
      results = $objCommunityDispatch.addTagToObject(uuid, label, object_type, object_uid, state);    
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][AddTagToObject] Error : " + e.message);
      logger.error("[CommunityJsonController][AddTagToObject] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddTagToObject " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  #  TagsAutoComplete(label)
  def TagsAutoComplete
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      label = extract_param("label",String,nil); 
      if(label.nil? )
        raise("No label !!");
      end 
      
      results = $objCommunityDispatch.tagsAutoComplete(label);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][TagsAutoComplete] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error
    }.to_json
    logger.debug("#STAT# [JSON] TagsAutoComplete " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # AddCommunityUsers
  #   params :
  #     uuid : required (String, user identifier)
  #     name : required (String, user name / pseudo)
  #     user_type : optional (String, default => default type)
  def AddCommunityUsers
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      
      uuid = extract_param("uuid",String,nil);
      if( uuid.nil? )
        raise("No uuid !!");
      end
      
      name = extract_param("name",String,nil);
      if( name.nil? )
        raise("No name !!");
      end
      
      user_type = extract_param("user_type",String,nil);
      
      results = $objCommunityDispatch.addCommunityUsers(uuid,name,user_type);    
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][AddCommunityUsers] Error : " + e.message);
      logger.error("[CommunityJsonController][AddCommunityUsers] Trace : " + e.backtrace.join("\n"));      
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddCommunityUsers " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # DeleteCommunityUsers
  #   params :
  #     uuid : required (String)  
  def DeleteCommunityUsers
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      
      uuid = extract_param("uuid",String,nil);
      if( uuid.nil? )
        raise("No uuid !!");
      end    
      results = $objCommunityDispatch.deleteCommunityUsers(uuid);    
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][DeleteCommunityUsers] Error : " + e.message);
      logger.error("[CommunityJsonController][DeleteCommunityUsers] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] DeleteCommunityUsers " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end  
  
  
  # AddCommentsAlert
  #   params :
  #     comment_id :  required (Integer)
  #     uuid :        required (String, user who alerting the comment)
  #     message :     required (String, why user is alerting the comment)
  def AddCommentsAlert
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      comment_id = extract_param("comment_id", Integer, nil)
      if comment_id.nil?
        raise "No comment_id !!"
      end
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No uuid"
      end
      
      message = extract_param("message",String,nil)
      if message.nil?
        raise "No message !!"
      end
      
      results = $objCommunityDispatch.addCommentsAlert(comment_id,uuid,message)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[CommunityJsonController][AddCommentAlert] Error : " + e.message);
      logger.error("[CommunityJsonController][AddCommentAlert] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddCommentsAlert " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # DeleteCommentsAlerts
  #   params :
  #     comments_ids :  required (Array of comment_id)
  #     uuids :         required (Array of uuid)
  #
  #   description : comments_ids[i] matches with uuids[i]
  #                 so uuids and comments_ids must have the same size
  def DeleteCommentsAlerts
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      comments_ids = extract_param("comments_ids", Array, nil)
      if comments_ids.nil?
        raise "No comments_ids !!"
      end
      
      uuids = extract_param("uuids", Array, nil)
      if uuids.nil?
        raise "No uuids"
      end
      
      results = $objCommunityDispatch.deleteCommentsAlerts(comments_ids,uuids)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[CommunityJsonController][DeleteCommentsAlerts] Error : " + e.message);
      logger.error("[CommunityJsonController][DeleteCommentsAlerts] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] DeleteCommentsAlerts " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end  
  
  
  # UpdateProfileDescription
  #   params :
  #     uuid : required (String)
  #     description : required (String)
  def UpdateProfileDescription
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      uuid = extract_param("uuid",String,nil);
      if( uuid.nil? )
        raise("No uuid !!");
      end
      
      description = extract_param("description",String,nil);
      if( description.nil? )
        raise("No description !!");
      end
      
      results = $objCommunityDispatch.updateProfileDescription(uuid,description);
      
    rescue => e
      error = -1;
      msg = e.message;
      logger.error("[CommunityJsonController][UpdateProfileDescription] Error : " + e.message);
      logger.error("[CommunityJsonController][UpdateProfileDescription] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json    
    logger.debug("#STAT# [JSON] UpdateProfileDescription " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method GetTagWithDetails
  #   params :
  #     tag_id : required (Integer)
  #     
  #   description : Returns a tag with id, label, 
  def GetTagWithDetails
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      tag_id = extract_param("tag_id",Integer,nil);
      if( tag_id.nil? )
        raise("No tag_id !!");
      end
      
      object_uid = extract_param("object_uid",String,nil);
      object_type = extract_param("object_type",String, nil);
      log_action = extract_param("log_action",String, "");
      log_cxt = extract_param("log_cxt",String,"");
      logs = {}
      logs[:object_uid] = object_uid
      logs[:object_type] = object_type
      logs[:tag_id] = tag_id
      logs[:log_cxt] = log_cxt
      logs[:log_action] = log_action
      results = $objCommunityDispatch.getTagWithDetails(tag_id, logs);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][GetTagWithDetails] Error : " + e.message);
      logger.error("[CommunityJsonController][GetTagWithDetails] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetTagWithDetails " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end  
  
  
  # Method GetTagsByUserWithDetails
  #   params :
  #     uuid : String
  #     sort : String (sort : SORT_TAG_RELEVANCE, SORT_TAG_ALPHABETIC)
  #     direction : String (direction : DESC, ASC)
  #   returns : Array[tag_struct]
  #     id : tag_id
  #     label
  #     notices_count
  #     lists_count
  #     weight
  def GetTagsByUserWithDetails
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      uuid = extract_param("uuid",String,nil);
      if( uuid.nil? )
        raise("No uuid !!");
      end
      
      sort = extract_param("sort",String,SORT_TAG_RELEVANCE);
      direction = extract_param("direction",String,DIRECTION_DOWN);
      if(SORT_TAG_RELEVANCE != sort and SORT_TAG_ALPHABETIC != sort and SORT_TAG_RANDOM != sort)
        raise("Uknown sort type #{sort} !! (Help : sort := tag_weight or label)")
      end
      if(DIRECTION_UP != direction and DIRECTION_DOWN != direction)
        raise("Uknown direction value #{direction} !! (Help : direction := up or down)")
      end
      
      max = extract_param("max",Integer,nil);
      page = extract_param("page",Integer,nil);
      
      results = $objCommunityDispatch.getTagsByUserWithDetails(uuid, sort, direction, page, max);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][GetTagsByUserWithDetails] Error : " + e.message);
      logger.error("[CommunityJsonController][GetTagsByUserWithDetails] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetTagsByUserWithDetails " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method GetTagDetailsByUser
  #   returns : TagStruct
  #     id : tag_id
  #     label
  #     notices_count : Number of notices (documents) tagged by user with tag
  #     simple_notices : Array of simple_notices tagged by user : notice(identifier, dc_title, object_tag_struct) 
  #     lists_count : Number of lists tagged by user with tag
  #     simple_lists : Array of simple_lists tagged by user : list(id, title, object_tag_struct)
  #                       object_tag_struct (id, state) : to change state or delete reference
  #     other_user_objects : Array of object_tag (other users references in the current tag)
  #                       object_tag_struct (id, title, object_type, object_uid, date, user_name) 
  def GetTagDetailsByUser
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      tag_id = extract_param("tag_id",Integer,0);
      if( tag_id == 0 )
        raise("No tag_id !!");
      end
      
      uuid = extract_param("uuid", String, nil);
      if(uuid.nil?)
        raise("No uuid !!")
      end
      
      results = $objCommunityDispatch.getTagDetailsByUser(tag_id,uuid);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][GetTagDetailsByUser] Error : " + e.message);
      logger.error("[CommunityJsonController][GetTagDetailsByUser] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetTagDetailsByUser " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end  
  
  
  # Method GetTagDetailsByObject
  #   returns : 
  #     tag nuage with tag_weight and object_tag_struct for each tag
  #     tag nuage is an array of TagStruct
  #       TagStruct fields : id, label, weight, user_object_tag  
  #       user_object_tag : ObjectTagStruct, is nil if authorized user hasn't referenced the current tag in object
  def GetTagsByObject
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      object_type = extract_param("object_type",Integer,0);
      if( object_type == 0 )
        raise("No object !!");
      end
      
      object_uid = extract_param("object_uid", String, nil);
      if(object_uid.nil?)
        raise("No object_uid !!")
      end
      
      uuid = extract_param("uuid", String, nil);      
      
      sort = extract_param("sort",String,SORT_TAG_RELEVANCE);
      direction = extract_param("direction",String,DIRECTION_DOWN);
      if(SORT_TAG_RELEVANCE != sort and SORT_TAG_ALPHABETIC != sort and SORT_TAG_RANDOM != sort)
        raise("Uknown sort type #{sort} !! (Help : sort := tag_weight or label)")
      end
      if(DIRECTION_UP != direction and DIRECTION_DOWN != direction)
        raise("Uknown direction value #{direction} !! (Help : direction := up or down)")
      end
      max = extract_param("max",Integer,nil);
      page = extract_param("page",Integer,nil);
      
      
      results = $objCommunityDispatch.getTagsByObject(object_type, object_uid, uuid, sort, direction, page, max);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][GetTagDetailsByUser] Error : " + e.message);
      logger.error("[CommunityJsonController][GetTagDetailsByUser] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json     
    logger.debug("#STAT# [JSON] GetTagsByObject " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end  
  
  
  # Method : ChangeObjectTagState
  #   params :
  #     object_type : required (Integer)
  #     object_uid : required (Integer)
  #     new_state : required (Integer)
  def ChangeObjectTagState
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      object_tag_id = extract_param("object_tag_id",Integer,0);
      if(object_tag_id.nil? or object_tag_id <= 0)
        raise("No object_tag_id !!")
      end
      
      new_state = extract_param("new_state",String,nil);
      if(new_state.nil?)
        raise("No new_state !!")
      end
      new_state = new_state.to_i
      if(new_state != TAG_PUBLIC and new_state != TAG_PRIVATE)
        raise("Invalid new_state #{new_state} , Help : TAG_PRIVATE = #{TAG_PRIVATE} and TAG_PUBLIC = #{TAG_PUBLIC} ")
      end
      results = $objCommunityDispatch.changeObjectTagState(object_tag_id,new_state);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][ChangeStateObjectTag] Error : " + e.message);
      logger.error("[CommunityJsonController][ChangeStateObjectTag] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json  
    logger.debug("#STAT# [JSON] ChangeObjectTagState " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method changeReferencedTagState
  #   params :
  #     tags_ids : Array of tag_id whom references state will be updated
  #     new_state : Integer
  #     uuid : String
  def ChangeReferencedTagsState
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      tags_ids = extract_param("tags_ids",Array,nil);
      if(tags_ids.nil?)
        raise("No tags_ids !!")
      end
      
      new_state = extract_param("new_state",String,nil);
      if(new_state.nil?)
        raise("No new_state !!")
      end
      new_state = new_state.to_i
      if(new_state != TAG_PUBLIC and new_state != TAG_PRIVATE)
        raise("Invalid new_state #{new_state} , Help : TAG_PRIVATE = #{TAG_PRIVATE} and TAG_PUBLIC = #{TAG_PUBLIC} ")
      end
      
      uuid = extract_param("uuid", String, nil);
      if(uuid.nil?)
        raise("No uuid !!")
      end
      results = $objCommunityDispatch.changeReferencedTagsState(tags_ids, new_state, uuid);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][ChangeReferencedTagsState] Error : " + e.message);
      logger.error("[CommunityJsonController][ChangeReferencedTagsState] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json  
    logger.debug("#STAT# [JSON] ChangeReferencedTagsState " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method DeleteUserReferencesTags
  #   params :
  #     tags_ids : Array of tag_id
  #     uuid : String 
  def DeleteUserReferencesTags
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      tags_ids = extract_param("tags_ids",Array,nil);
      if(tags_ids.nil?)
        raise("No tags_ids !!")
      end
      
      uuid = extract_param("uuid",String,nil);
      if(uuid.nil?)
        raise("No uuid !!")
      end      
      
      results = $objCommunityDispatch.deleteUserReferencesTags(tags_ids,uuid);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][DeleteUserReferencesTags] Error : " + e.message);
      logger.error("[CommunityJsonController][DeleteUserReferencesTags] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json  
    logger.debug("#STAT# [JSON] DeleteUserReferencesTags " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  def DeleteObjectTagReference
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      object_tag_id = extract_param("object_tag_id",Integer,0);
      if(object_tag_id.nil? or object_tag_id <= 0)
        raise("No object_tag_id !!")
      end
      
      results = $objCommunityDispatch.deleteObjectTagReference(object_tag_id);
      
    rescue => e
      error = -1;
      logger.error("[CommunityJsonController][DeleteObjectTagReference] Error : " + e.message);
      logger.error("[CommunityJsonController][DeleteObjectTagReference] Trace : " + e.backtrace.join("\n"))
      msg = e.message;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json       
    logger.debug("#STAT# [JSON] DeleteObjectTagReference " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method : GetCommentsListByNote
  # params:
  #   object_type : required (Integer)
  #   object_uid : required (String)
  #   note : required (Integer)
  def GetCommentsByNote
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    msg = nil
    begin
      
      object_type = extract_param("object_type", Integer, 0)
      if(object_type.nil? or object_type <= 0)
        raise("No object !!")
      end
      
      object_uid = extract_param("object_uid", String, nil)
      if object_uid.nil?
        raise "No object_uid !!"
      end
      
      note = extract_param("note", Integer, 0)
      if note.nil? or note <= 0
        raise "No note !!"
      end
      
      results = $objCommunityDispatch.getCommentsByNote(object_type, object_uid, note)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[CommunityJsonController][GetCommentsByNote] Error : " + e.message);
      logger.error("[CommunityJsonController][GetCommentsByNote] Trace : " + e.backtrace.inspect("\n"));   
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetCommentsByNote " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # Method : GetMostPertinentComment
  # params:
  #   object_uid
  def GetMostPertinentComment
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      object_uid = extract_param("object_uid", String, nil)
      if object_uid.nil?
        raise "No object"
      end
      
      results = $objCommunityDispatch.getMostPertinentComment(object_uid)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[CommunityJsonController][getMostPertinentComment] Error : " + e.message);
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetMostPertinentComment " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
end
