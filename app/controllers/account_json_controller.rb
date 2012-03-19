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
#
# This methods are accessible by this url: <tt>http ://<SERVEUR>/account_json/<METHOD></tt>
#
# == Variables in HTTP Header
# See JsonApplicationController and method analyse_request
# 
#
# Parameters in <b>bold</b> are required, the <em>others</em> are optionals
class AccountJsonController < JsonApplicationController
  
  # == Add statistic when a ressource is consulted 
  #
  # Parameters:
  # * <b>id_notice</b> : id of records. String.  
  # * <b>indoor</b> : is indoor at bpi. Integer (0 or 1).
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def AddLogConsultRessource
    error = 0;
    res = nil;
    _sTime = Time.now().to_f
    begin
      notice_id = extract_param("id_notice", String, nil)
      if notice_id.nil?
        raise "No notice_id"
      end
      
      indoor = extract_param("indoor", Integer, 0)
      
      res = $objAccountDispatch.addLogConsultRessource(notice_id, indoor);
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][AddLogConsultRessource] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => res,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddLogConsultRessource " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Add records for a user account
  #
  # Parameters:
  # * <b>id_notices[]</b> : array of id records. Array.  
  # * <b>uuid</b> : id user. String
  # @return {results => array [UserRecord.id] , error => error if error != 0, message => "error message"}
  def SaveNoticesByUser
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      id_notices = extract_param("id_notices", Array, nil)
      if id_notices.nil?
        raise "No notices"
      end
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      results = $objAccountDispatch.saveNoticesByUser(id_notices, uuid);
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][saveNotices] Error : " + e.message);
    end
    
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] saveNotices " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end 
  
  
  # == Delete a UserRecords for a user
  #
  # Parameters:
  # * <b>user_record_ids[]</b> : array of id #UserRecord. Array.  
  # * <b>uuid</b> : id user. String
  # @return {results => Integer , error => error if error != 0, message => "error message"}
  def DeleteUserRecordsByUser
    error = 0;
    results = nil;
    msg = nil;
    _sTime = Time.now().to_f
    begin
      
      user_record_ids = extract_param("user_record_ids", Array, nil)
      if user_record_ids.nil?
        raise "No notices"
      end
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      results = $objAccountDispatch.deleteUserRecordsByUser(user_record_ids, uuid);
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][DeleteNoticesByUser] Error : #{e.message}");
      logger.error("[AccountJsonController][DeleteNoticesByUser] Error : " + e.backtrace.join("\n"));
    end
    
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] DeleteNoticesByUser " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end 
  
  
  # == Get UserRecords for a user
  # 
  # Parameters:
  # * <b>uuid</b> : id user. String
  # * <em>max</em> : number #UserRecord to return. Integer. (default 10)
  # * <em>page</em> : page. Integer. (default 1)
  # * <em>sort</em> : sorting criteria. String. [type or title or author or date] (default type) 
  # * <em>direction</em> : direction. String [up or down] (default up)
  # @return {results => array of #UserItem , error => error if error != 0, message => "error message"}
  def GetUserRecordsByUser
    error = 0;
    results = nil;
    _sTime = Time.now().to_f
    begin
      
      max = extract_param("max", Integer, 10)
      page = extract_param("page", Integer, 1)
      sort = extract_param("sort", String, SORT_TYPE)
      direction = extract_param("direction", String, DIRECTION_UP)
      
      logger.debug("[AccountJsonController][GetUserRecordsByUser] sort : #{sort} direction : #{direction}")
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      results = $objAccountDispatch.getUserRecordsByUser(uuid, max, page, sort, direction);
      
    rescue => e
      error = -1;
      logger.error("[AccountJsonController][GetUserRecordsByUser] Error : " + e.message);
    end
    
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error
    }.to_json
    logger.debug("#STAT# [JSON] GetUserRecordsByUser " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end 
  
  # == Create or update a list for a user
  # 
  # Send -1 for list_id if it's a new list
  #
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number. default = -1
  # * <b>title</b> : title. String
  # * <b>uuid</b> : user id #CommunityUser.uuid. String
  # * <em>ptitle</em> : subtitle. String
  # * <em>description</em> : description. String.
  # * <em>state</em> : state public or private. Integer [0 or 1]
  # @return {results => #ListUser , error => error if error != 0, message => "error message"}
  def SaveList
    _sTime = Time.now().to_f
    error = 0;
    results = nil;
    msg = nil
    begin
      list_id = extract_param("list_id", Integer, -1)
      
      title = extract_param("title", String, nil)
      if title.nil?
        raise "No title"
      end
      
      ptitle = extract_param("ptitle", String, "")
      description = extract_param("description", String, "")
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      state = extract_param("state", Integer, nil, -1)
      
      logger.debug("[AccountJsonController] saveList: [list_id:#{list_id} title:#{title} ptitle:#{ptitle} uuid:#{uuid} state:#{state}")
      
      results = $objAccountDispatch.saveOrUpdateList(list_id, title, ptitle, uuid, description,state)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][saveList] Error : " + e.message);
      logger.error("[AccountJsonController][saveList] Trace : " + e.backtrace.join("\n"));      
    end
    
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] saveList " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Change state of List
  #
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number
  # * <b>uuid</b> : user id #CommunityUser.uuid. String
  # * <em>state</em> : state public or private. Integer [0 or 1]
  # * <em>date_public</em> : timestamp (default: nil)
  # * <em>date_end_public</em> : timestamp (default: nil)
  # @return {results => Integer , error => error if error != 0, message => "error message"}
  def ChangeState
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      state = extract_param("state", Integer, nil, -1)
      if state.nil?
        raise "No state"
      end 
      
      date_public = extract_param("date_public", Integer, nil)
      date_end_public = extract_param("date_end_public", Integer, nil)
      results = $objAccountDispatch.changeStateList(list_id, uuid, state, date_public, date_end_public)
      
      logger.error(results)
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][ChangeState] Error : " + e.message);
    end
    
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] ChangeState " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Move down a UserRecordList in a List
  #
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number
  # * <b>user_record</b> : #UserRecord.id . String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def DownNoticeInList
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      user_record = extract_param("user_record", String, nil)
      if user_record.nil?
        raise "No notices"
      end
      max = ObjectsCount.getObjectCountById(ENUM_LIST, list_id).notices_count
      results = $objAccountDispatch.downNoticeInList(list_id, user_record, max)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][downNoticeInlist] Error : " + e.message);
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] downNoticeInlist " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Move up a UserRecordList in a List
  #
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number
  # * <b>user_record</b> : #UserRecord.id . String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def UpNoticeInList
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      user_record = extract_param("user_record", String, nil)
      if user_record.nil?
        raise "No notices"
      end
      
      results = $objAccountDispatch.upNoticeInList(list_id, user_record)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][upNoticeInlist] Error : " + e.message);
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] upNoticeInlist " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Add Records in a List
  #
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number
  # * <b>id_notices</b> : Array of #Record.id . String
  # * <b>uuid</b> : #CommunityUser.uid . String
  # @return {results => #List , error => error if error != 0, message => "error message"}
  def AddNoticesToList
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      id_notices = extract_param("id_notices", Array, nil)
      if id_notices.nil?
        raise "No notices"
      end
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      results = $objAccountDispatch.addNoticesToList(list_id, uuid, id_notices)
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][AddNoticesToList] Error : " + e.message);
    end 
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddNoticesToList " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Add UserRecords in a List
  # 
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number.
  # * <b>user_records_array</b> : Array of #UserRecord.id . String
  # * <b>uuid</b> : #CommunityUser.uid . String
  # @return {results => #List , error => error if error != 0, message => "error message"}
  def AddUserRecordsToList
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      user_records_array = extract_param("user_records_array", Array, nil)
      if user_records_array.nil?
        raise "No notices"
      end
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      results = $objAccountDispatch.addUserRecordsToList(list_id, uuid, user_records_array)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][AddUserRecordsToList] Error : " + e.message);
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddUserRecordsToList " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Delete a ListUserRecords
  # 
  # Delete items of list for a user
  # 
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number.
  # * <b>list_user_records_array</b> : Array of #ListUserRecord.id . String
  # * <b>uuid</b> : #CommunityUser.uid . String
  # @return {results => Integer , error => error if error != 0, message => "error message"}
  def DeleteListUserRecords
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      list_user_records_array = extract_param("list_user_records_array", Array, nil)
      if list_user_records_array.nil?
        raise "No list_user_records_array"
      end
      results = $objAccountDispatch.deleteListUserRecords(list_id, uuid, list_user_records_array)
      
    rescue => e
      error = -1;
      logger.error("[AccountJsonController][deleteListUserRecords] Error : " + e.message);
      msg = e.message
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] deleteListUserRecords " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Delete a List
  # 
  # Delete a list for a user
  # 
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number.
  # * <b>uuid</b> : #CommunityUser.uid . String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def DeleteList
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No user"
      end
      
      results = $objAccountDispatch.deleteList(list_id, uuid)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][DeleteList] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] DeleteList " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Get a list by its id
  # 
  # Parameters:
  # * <b>list_id</b> : list id #List.id. Number
  # * <b>uuid</b> : #CommunityUser.uid . String
  # * <em>detailed_list</em> all detail. String (true or false) default: false
  # * <em>notice_max</em> : max notices. Integer. default: all
  # * <em>page</em> : page. Integer. default = 1
  # * <tt>log_ctx</tt> : context of this call for statistics. String. ex: search, notice, account, basket
  # * <tt>log_action</tt> : cause of this call for statistics. String (ex: consult, rebonce, pdf, email, print )
  # @return {results => #Struct::ListUser , error => error if error != 0, message => "error message"}
  def GetListById
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      list_id = extract_param("list_id", Integer, nil)
      if list_id.nil?
        raise "No List Id"
      end
      uuid = extract_param("uuid", String, nil)
      
      detailed_list = extract_param("detailed_list", String, "false")
      detailed_list = (detailed_list == "false") ? false : true
      
      notice_max = extract_param("notice_max",Integer,nil);
      page = extract_param("page",Integer,nil); 
      
      log_action = extract_param("log_action",String, "");
      log_cxt = extract_param("log_cxt",String,"");
      logs = {}
      logs[:log_cxt] = log_cxt
      logs[:log_action] = log_action
      
      results = $objAccountDispatch.getListById(list_id, uuid, detailed_list, notice_max, page, logs)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][GetListById] Error : " + e.message);
      logger.error("[AccountJsonController][GetListById] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetListById " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Get lists by notice
  # 
  # Parameters:
  # * <b>doc_id</b> : #Record.id. String.
  # * <em>list_max</em> : max lists. Integer default: 20
  # * <em>page</em> : page. Integer. default: 1
  # @return {results => #Struct::ListUser , error => error if error != 0, message => "error message"}
  def GetListsByNotice
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      doc_id = extract_param("doc_id", String, nil)
      if doc_id.nil?
        raise "No doc Id"
      end
      
      list_max = extract_param("list_max",Integer,DEFAULT_MAX_LIST);
      page = extract_param("page",Integer,DEFAULT_PAGE_LIST); 
      
      results = $objAccountDispatch.getListsByNotice(doc_id, list_max, page)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][GetListsByNotice] Error : " + e.message);
      logger.error("[AccountJsonController][GetListsByNotice] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetListsByNotice " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Add subscription on object
  # 
  # Parameters:
  # * <b>object_type</b> : Type of Object. Integer. (ENUM_NOTICE = 1, ENUM_LIST = 2, ENUM_COMMENT = 3, ENUM_TAG = 4, ENUM_COMMUNITY_USER = 5, ENUM_SUBSCRIPTION = 6, ENUM_RSS_FEED = 7, ENUM_SEARCH_HISTORY = 8)
  # * <b>object_uid</b> : Object id. String.
  # * <b>uid</b> : #CommunityUser.uid . String
  # * <em>mail_notification</em> : with email notification. Integer. default: 0
  # * <em>state</em> : state. Integer. default: 1
  # @return {results => #Subscription , error => error if error != 0, message => "error message"}
  def AddSubscription
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      object_type = extract_param("object_type", Integer, 0)
      if object_type.nil? or object_type <= 0
        raise "No object_type !!"
      end
      
      object_uid = extract_param("object_uid", String, nil)
      if object_uid.nil?
        raise "No object_uid !!"
      end
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No uuid"
      end
      
      mail_notification = extract_param("mail_notification",Integer,NO_MAIL_NOTIFICATION)
      if(mail_notification != NO_MAIL_NOTIFICATION and mail_notification != MAIL_NOTIFICATION)
        raise("Invalid mail_notification, (Help : MAIL_NOTIFICATION = #{MAIL_NOTIFICATION} and NO_MAIL_NOTIFICATION = #{NO_MAIL_NOTIFICATION})  !!")
      end
      
      state = extract_param("state", Integer, SUBSCRIPTION_ACTIVE)
      if(state != SUBSCRIPTION_ACTIVE and state != SUBSCRIPTION_FINISHED and state != SUBSCRIPTION_NOTIFIED)
        raise("Invalid state, (Help : SUBSCRIPTION_FINISHED = #{SUBSCRIPTION_FINISHED} , SUBSCRIPTION_NOTIFIED = #{SUBSCRIPTION_NOTIFIED} and SUBSCRIPTION_ACTIVE = #{SUBSCRIPTION_ACTIVE} !!")
      end
      
      results = $objAccountDispatch.addSubscription(object_type,object_uid,uuid,mail_notification,state)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][AddSubscription] Error : " + e.message);
      logger.error("[AccountJsonController][AddSubscription] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddSubscription " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  
  # == Update subscription on object
  # 
  # Parameters:
  # * <b>object_type</b> : Type of Object. Integer. (ENUM_NOTICE = 1, ENUM_LIST = 2, ENUM_COMMENT = 3, ENUM_TAG = 4, ENUM_COMMUNITY_USER = 5, ENUM_SUBSCRIPTION = 6, ENUM_RSS_FEED = 7, ENUM_SEARCH_HISTORY = 8)
  # * <b>object_uid</b> : Object id. String.
  # * <b>uid</b> : #CommunityUser.uid . String
  # * <em>mail_notification</em> : with email notification. Integer. default: 0
  # * <em>state</em> : state. Integer. default: 1
  # @return {results => #Subscription , error => error if error != 0, message => "error message"}
  def UpdateSubscription
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      object_type = extract_param("object_type", Integer, nil)
      if object_type.nil?
        raise "No object !!"
      end
      
      object_uid = extract_param("object_uid", String, nil)
      if object_uid.nil?
        raise "No object_uid !!"
      end      
      
      uuid = extract_param("uuid", String, nil)
      if uuid.nil?
        raise "No uuid !!"
      end
      
      mail_notification = extract_param("mail_notification",String,nil)
      
      state = extract_param("state", String, nil)
      
      results = $objAccountDispatch.updateSubscription(object_type, object_uid, uuid, mail_notification, state)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][updateSubscription] Error : " + e.message);
      logger.error("[AccountJsonController][updateSubscription] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] UpdateSubscription " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Delete subscriptions on objects
  # 
  # objects[i] must matches with objects_ids[i] and uuids[i] to get one subscription.
  # Arrays objects, objects_ids and subscriptions must have same size.
  #
  # Parameters:
  # * <b>objects</b> : array of Type of Object. Array Integer. (ENUM_NOTICE = 1, ENUM_LIST = 2, ENUM_COMMENT = 3, ENUM_TAG = 4, ENUM_COMMUNITY_USER = 5, ENUM_SUBSCRIPTION = 6, ENUM_RSS_FEED = 7, ENUM_SEARCH_HISTORY = 8)
  # * <b>objects_ids</b> : array of Object uid. Array String.
  # * <b>uids</b> : Array #CommunityUser.uid . Array String
  # @return {results => Integer , error => error if error != 0, message => "error message"}
  def DeleteSubscriptions
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      objects = extract_param("objects", Array, nil)
      if objects.nil?
        raise "No objects !!"
      end
      
      objects_ids = extract_param("objects_ids", Array, nil)
      if objects_ids.nil?
        raise "No objects_ids !!"
      end
      
      uuids = extract_param("uuids", Array, nil)
      if uuids.nil?
        raise "No uuids"
      end
      
      results = $objAccountDispatch.deleteSubscriptions(objects,objects_ids,uuids)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][DeleteSubscriptions] Error : " + e.message);
      logger.error("[AccountJsonController][DeleteSubscriptions] Trace : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] DeleteSubscriptions " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end  
  
  # == Get Profile for a #CommunityUser
  # 
  # One of the two parameters is required (uuid or uuid_md5)
  # 
  # Parameters:
  # * <em>uuid</em> : #CommunityUser.uid. String
  # * <em>uuid_md5</em> : #CommunityUser.MD5. String.
  # @return {results => #Struct::Profile , error => error if error != 0, message => "error message"}
  def GetProfile
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      uuid = extract_param("uuid", String, nil)
      
      uuid_md5 = extract_param("uuid_md5", String, nil)
      
      if uuid.nil? and uuid_md5.nil?
        raise "No uuid !!"
      end
      
      log = false
      if !uuid_md5.blank?
        uuid = $objCommunityDispatch.getUserByIdentifier(uuid_md5)
        log = true
      end
      
      if (uuid.nil?)
        raise "No uuid !!"
      end
      
      results = $objAccountDispatch.getProfile(uuid, log)
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][GetProfile] Error : " + e.message);
      logger.debug("[AccountJsonController][GetProfile] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] GetProfile " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Save critera for a research in profil user
  # 
  # params : json => {"id_history_search" => [job_id,job_id]}
  # ex: {"1" => [123, 124, 125}, "23" => [135, 136]} 
  # 
  # id_history_search : is sended by the method Search in #json_controller
  # 
  # Parameters:
  # * <b>uuid</b> : #CommunityUser.uid. String
  # * <b>params</b> : json. String.
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def SaveUserHistorySearches
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      
      if INFOS_USER_CONTROL and !@info_user.nil?
        uuid = @info_user.uuid_user
      else
        uuid = extract_param("uuid", String, nil)
      end
      if(uuid.nil?)
        raise("No uuid !!")
      end
      
      params = extract_param("params", String, nil)
      if(params.nil?)
        raise("No params !!")
      end
      p = ActiveSupport::JSON.decode(params)
      results = $objAccountDispatch.saveUserHistorySearches(uuid, p)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][SaveUserHistorySearches] Error : " + e.message);
      logger.error("[AccountJsonController][SaveUserHistorySearches] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json    
    logger.debug("#STAT# [JSON] SaveUserHistorySearches " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end 
  
  # == Delete history_searches for a user
  # 
  # Parameters:
  # * <b>user_searches_ids</b> : array #UserHistorySearch.id. Array String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def DeleteUserHistorySearches
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      user_searches_ids = extract_param("user_searches_ids", Array, nil)      
      if(user_searches_ids.nil?)
        raise("No user_searches_ids !!")
      end
      results = $objAccountDispatch.deleteUserHistorySearches(user_searches_ids)
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][DeleteUserHistorySearches] Error : " + e.message);
      logger.error("[AccountJsonController][DeleteUserHistorySearches] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json    
    logger.debug("#STAT# [JSON] DeleteUserHistorySearches " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Get UserHistorySearches for a user
  # 
  # Parameters:
  # * <b>uuid</b> : #CommunityUser.uid. String
  # * <em>max</em> : number #UserRecord to return. Integer. (default 10)
  # * <em>page</em> : page. Integer. (default 1)
  # * <em>sort</em> : sorting criteria. String. [type or title or author or date] (default date) 
  # * <em>direction</em> : direction. String [up or down] (default down)
  # @return {results => Array , error => error if error != 0, message => "error message"}
  def GetUserSearchesHistory
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      uuid = extract_param("uuid",String, nil)      
      if(uuid.nil?)
        raise("No uuid !!")
      end
      
      max = extract_param("max", Integer, 10)
      page = extract_param("page", Integer, 1)
      sort = extract_param("sort", String, SORT_DATE)
      direction = extract_param("direction", String, DIRECTION_DOWN)
      
      results = $objAccountDispatch.getUserSearchesHistory(uuid, max, page, sort, direction)
      
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][GetUserSearchesHistory] Error : " + e.message);
      logger.error("[AccountJsonController][GetUserSearchesHistory] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json    
    logger.debug("#STAT# [JSON] GetUserSearchesHistory " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Get Alerts for a user
  # 
  # Parameters:
  # * <b>uuid</b> : #CommunityUser.uid. String
  # * <em>max</em> : number #UserRecord to return. Integer. (default 10)
  # * <em>page</em> : page. Integer. (default 1)
  # * <em>sort</em> : sorting criteria. String. [type or title or author or date] (default date) 
  # * <em>direction</em> : direction. String [up or down] (default down)
  # @return {results => Array , error => error if error != 0, message => "error message"}
  def getAlertsForUser
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      uuid = extract_param("uuid",String, nil)      
      if(uuid.nil?)
        raise("No uuid !!")
      end
      
      max = extract_param("max", Integer, 10)
      page = extract_param("page", Integer, 1)
      sort = extract_param("sort", String, SORT_DATE)
      direction = extract_param("direction", String, DIRECTION_DOWN)
      
      results = $objAccountDispatch.getAlertsForUser(uuid, max, page, sort, direction)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][getAlertsForUser] Error : " + e.message);
      logger.error("[AccountJsonController][getAlertsForUser] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json   
    logger.debug("#STAT# [JSON] getAlertsForUser " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Delete an alert comment
  # 
  # This method delete a comment and alerts
  #
  # Parameters:
  # * <b>comment_id</b> : #Comment.id. String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def DeleteCommentAlerted
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin
      comment_id = extract_param("comment_id",String, nil)
      if(comment_id.nil?)
        raise("No comment_id !!")
      end
      
      results = $objAccountDispatch.deleteCommentAlerted(comment_id)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][DeleteCommentAlerted] Error : " + e.message);
      logger.error("[AccountJsonController][DeleteCommentAlerted] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json  
    logger.debug("#STAT# [JSON] DeleteCommentAlerted " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Delete all alert on a comment
  # 
  # This method delete only alerts
  #
  # Parameters:
  # * <b>comment_id</b> : #Comment.id. String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def DeleteAlertsOnComment
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      comment_id = extract_param("comment_id",String, nil)      
      if(comment_id.nil?)
        raise("No comment_id !!")
      end
      
      results = $objAccountDispatch.deleteAlertsOnComment(comment_id)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][DeleteCommentAlerted] Error : " + e.message);
      logger.error("[AccountJsonController][DeleteCommentAlerted] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json 
    logger.debug("#STAT# [JSON] DeleteCommentAlerted " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Save user preferences
  # 
  # Parameters:
  # * <b>uid</b> : #CommunityUser.uid. String
  # * <b>desc</b> : description. String
  # * <b>params</b> : infos json. String JSON
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def SaveUserParams
    error = 0;
    results = nil;
    msg = nil;
    _sTime = Time.now().to_f
    begin
      uuid = extract_param("uuid", String , nil)
      desc = extract_param("desc", String , nil)
      params = extract_param("params", String, nil)
      if (uuid.nil?)
        raise("no uuid")
      end
      if (params.nil?)
        raise("no params")
      end
      
      results = $objAccountDispatch.SaveUserParams(uuid, params, desc)
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][SaveUserParams] Error : " + e.message);
      logger.error("[AccountJsonController][SaveUserParams] Trace : " + e.backtrace.join("\n"))
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] SaveUserParams " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Delete all subscription availability for an user 
  # 
  # Parameters:
  # * <b>uid</b> : #CommunityUser.uid. String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def DeleteAllAlerts
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      uuid = extract_param("uuid", String, nil)
      if(uuid.nil?)
        raise("No uuid !!")
      end
      
      results = $objAccountDispatch.deleteAllAlerts(uuid)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][DeleteAllAlerts] Error : " + e.message);
      logger.error("[AccountJsonController][DeleteAllAlerts] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json  
    logger.debug("#STAT# [JSON] DeleteAllAlerts " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Notify all subscriptions by mail for an user 
  # 
  # Parameters:
  # * <b>uid</b> : #CommunityUser.uid. String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def NotifyAllByMail
    error = 0;
    results = nil;
    msg = nil
    _sTime = Time.now().to_f
    begin      
      uuid = extract_param("uuid", String, nil)
      if(uuid.nil?)
        raise("No uuid !!")
      end
      
      results = $objAccountDispatch.notifyAllByMail(uuid)
      
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][NotifyAllByMail] Error : " + e.message);
      logger.error("[AccountJsonController][NotifyAllByMail] Trace : " + e.backtrace.join("\n"))
    end      
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => results,
      :error    => error,
      :message => msg
    }.to_json  
    logger.debug("#STAT# [JSON] NotifyAllByMail " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Add log cart 
  # 
  # This method is used for statistics
  # 
  # Parameters:
  # * <em>first</em> : first use, Integer (0 or 1)
  # * <b>id_notices</b>: Array #Record.id, Array String
  # @return {results => boolean , error => error if error != 0, message => "error message"}
  def AddLogCarts
    error = 0;
    res = nil;
    _sTime = Time.now().to_f
    begin
      first = extract_param("first", Integer, 0)
      id_notices = extract_param("id_notices", Array, nil)
      if id_notices.nil?
        raise "No notices"
      end
      
      res = $objAccountDispatch.addLogCarts(id_notices, first);
    rescue => e
      error = -1;
      msg = e.message
      logger.error("[AccountJsonController][AddLogCarts] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => { :results  => res,
      :error    => error,
      :message => msg
    }.to_json
    logger.debug("#STAT# [JSON] AddLogCarts " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # Sample url use:
  # http://127.0.0.1/account_json/GetAvailibilityCountByNotice?doc_id=4242
  # http://127.0.0.1/account_json/DownNoticeInList?list_id=1&user_record=424242
  # http://127.0.0.1/account_json/UpNoticeInList?list_id=1&user_record=424242
  # http://localhost/account_json/AddLogCarts?id_notices=1
  # http://localhost/account_json/AddLogCarts?id_notices=1&type=print
  # http://localhost/account_json/AddLogCarts?id_notices=1&type=mail
  # http://localhost/account_json/AddLogCarts?id_notices=1&type=export
  # http://localhost/account_json/SaveList?title=title&ptitle=ptitle&uuid=gee
  # http://localhost/account_json/SaveList?list_id=1&title=title%20modifi%C3%A9&ptitle=ptitle&uuid=gee
  # http://localhost/account_json/ChangeState?list_id=1&state=1&uuid=gee
  # http://localhost/account_json/AddNoticesToList?list_id=1&uuid=gee&id_notices[]=246841;14&id_notices[]=246854;14&id_notices[]=246854;14&id_notices[]=246855;14
  # http://localhost/account_json/SaveNoticesByUser?id_notices[]=246856;14&uuid=gee
  # http://localhost/account_json/AddUserRecordsToList?list_id=1&uuid=gee&user_records_array[]=246856,14,gee
  # http://localhost/account_json/DeleteListUserRecords?list_id=1&uuid=gee&list_user_records_array[]=246856,14,gee,1&&list_user_records_array[]=246856,14,gees,1
  # http://localhost/account_json/DeleteListUserRecords?list_id=1&uuid=gee&list_user_records_array[]=246856,14,gee,1&&list_user_records_array[]=246857,14,gee,2
  # http://localhost/account_json/DeleteListUserRecords?list_id=1&uuid=gee&list_user_records_array[]=246856,14,gee,1&&list_user_records_array[]=246857,14,gee,1  
end
