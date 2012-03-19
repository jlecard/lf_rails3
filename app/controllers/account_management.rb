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

class AccountManagement < CommunityController
  include ApplicationHelper
  
  def setInfosUser(infoUser)
    @info_user = infoUser
    @log_management = LogManagement.new
    @log_management.setInfosUser(@info_user)
  end
  
  # This method save "notices" (with identifier) in all docs for user
  def saveNoticesByUser(id_notices, uuid)
    Notice.transaction do 
      return saveNoticesByUserOffTransaction(id_notices, uuid, "mydoc")
    end
  end
  
  def saveNoticesByUserOffTransaction(id_notices, uuid, from = nil)
    logger.debug("[AccountManagement] saveNoticesByUserOffTransaction id_notices: #{id_notices.inspect} uuid: #{uuid}")
    # TODO: valid if user is uuid
    hash = Hash.new()
    id_notices.each do |doc|
      begin
        if UserRecord.existById?(doc, uuid)
          logger.debug("[AccountManagement] saveNoticesByUserOffTransaction : UserRecord exist")
          #          raise "#{doc} already save"
          idDoc, idColl, idSearch = UtilFormat.parseIdDoc(doc)
          hash[doc] = "#{idDoc},#{idColl},#{uuid}"
        else
          # create notice
          if copyNotice(doc)
            idDoc, idColl, idSearch = UtilFormat.parseIdDoc(doc)
            logger.debug("[AccountManagement] saveNoticesByUserOffTransaction : IdDoc => #{idDoc} idColl => #{idColl} idSearch => #{idSearch}")
            
            if !idDoc.blank? and !idColl.blank?
              item = UserRecord.addUserRecord(idDoc, idColl, uuid)
              
              if !item.nil?
                hash[doc] = item.id.to_s
                if (!from.nil?)
                  @log_management.addLogSaveNotice(idDoc, from)
                end
              else
                raise "Id nil for #{doc}"
              end
              
            else
              raise "Id notice blank #{doc}"
            end
          else
            logger.error("[AccountManagement] doc not found")
            raise "Id notice blank #{doc}"
          end
        end
      rescue => e
        logger.error("[AccountManagement] saveNoticesByUserOffTransaction : #{e.message}")
        raise e
      end
    end
    
    return hash
  end
  
  def deleteUserRecordsByUser(record_user_ids, uuid)
    # nb rows affected
    rows = UserRecord.deleteUserRecordsByUser(record_user_ids, uuid)
    logger.debug("[AccountManagement] deleteUserRecordsByUser : #{record_user_ids} => #{rows}")
    return rows
  end
  
  def getUserRecordsByUser(uuid, max, page, sort, direction)
    if uuid.blank?
      raise "uuid blank"
    end
    
    user_records = UserRecord.getUserRecordsByUser(uuid, max, page, sort, direction)
    tmp = []
    if !user_records.empty?
      
      user_records.each do |u|
        user_item = Struct::UserItem.new()
        user_item.id = u.id.to_s
        user_item.identifier = "#{u.doc_identifier}#{ID_SEPARATOR}#{u.doc_collection_id}";
        user_item.title = u.dc_title;
        user_item.type = u.dc_type;
        user_item.author = u.dc_author;
        user_item.date_inserted = u.date
        list_item = []
        
        # Todo: Optimize this request "u.lists"
        u.lists.each do |l|
          list_item << Struct::Label.createLabel(l.id, l.title)
        end
        
        user_item.lists = list_item
        tmp << user_item
      end
    end
    return tmp
  end
  
  
  ### List ###
  def saveOrUpdateList(list_id, title, ptitle, uuid, description, state)
    cu = CommunityUsers.getCommunityUserByUuid(uuid)
    if(cu.nil?)
      raise("No user with uuid = #{uuid} ")
    end
    if (INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user != uuid)
      raise("Can't add or modify list for another User!")
    end
    logger.debug("[AccountManagement] saveOrUpdateList : list_id: #{list_id} title: #{title}, ptitle:#{ptitle}, uuid: #{uuid}, description : #{description}, state : #{state}")
    if list_id == -1
      return List.createList(title, ptitle, uuid, description, state)
    else
      return List.updateList(list_id, title, ptitle, uuid, description, state)
    end
  end
  
  
  def changeStateList(list_id, uuid, state, datePublic=nil, dateEndPublic=nil)
    logger.debug("[AccountManagement] changeStateList : list_id: #{list_id} state: #{state}, datePublic:#{datePublic}, dateEndPublic: #{dateEndPublic} uuid: #{uuid}")
    
    if List.exists?(list_id)
      # Increment/Decrement lists_count_public for user
      #      oc = ObjectsCount.getObjectCountById(ENUM_COMMUNITY_USER, uuid)
      #      if(!oc.nil?)
      #        ObjectsCount.updateListsCountPublic(oc, 1, state)
      #      end
      return List.changeState(list_id, state, datePublic, dateEndPublic)
    else
      logger.warn("[AccountManagement] changeStateList : id:#{list_id} not found")
      raise "List Not Found"
    end
  end
  
  
  def addNoticesToList(list_id, uuid, id_notices)
    List.transaction do
      logger.debug("[AccountManagement] addNoticesToList : list_id: #{list_id} id_notices: #{id_notices}")
      results = saveNoticesByUserOffTransaction(id_notices, uuid)
      if !results.empty?
        user_records_array = []
        results.each do |k, v|
          logger.debug("[AccountManagement] addNoticesToList : k #{k} v #{v}")
          user_records_array << v.to_s
          @log_management.addLogSaveNotice(v.to_s, "list")
        end
        logger.debug("[AccountManagement] addNoticesToList : list_id: #{list_id} user_records_array: #{user_records_array}")
        return addUserRecordsToListOffTransaction(list_id, uuid, user_records_array)
      end
    end
  end
  
  
  def addUserRecordsToListOffTransaction(list_id, uuid, user_records_array, transaction=true)
    logger.debug("[AccountManagement] addUserRecordsToListOffTransaction : list_id: #{list_id} user_records_array: #{user_records_array}")
    response = ListUserRecord.createListUserRecords(user_records_array, list_id)
    return response
  end
  
  
  def downNoticeInList(list_id, user_record, max)
    logger.debug("[AccountManagement] dowwnNoticeInList : list_id: #{list_id} user_record: #{user_record} max #{max}")
    return ListUserRecord.downNoticeInList(list_id, user_record, max)
  end
  
  
  def upNoticeInList(list_id, user_record)
    logger.debug("[AccountManagement] upNoticeInList : list_id: #{list_id} user_record: #{user_record}")
    return ListUserRecord.upNoticeInList(list_id, user_record)
  end
  
  def addUserRecordsToList(list_id, uuid, user_records_array)
    List.transaction do
      logger.debug("[AccountManagement] addUserRecordsToList : list_id: #{list_id} user_records_array: #{user_records_array}")
      return addUserRecordsToListOffTransaction(list_id, uuid, user_records_array)
    end
  end
  
  
  def deleteListUserRecords(list_id, uuid, list_user_records_array)
    logger.debug("[AccountManagement] deleteUserRecordsList : list_id: #{list_id} uuid: #{uuid} list_user_records_array: #{list_user_records_array}")
    return ListUserRecord.deleteByListAndArrayId(list_id, uuid, list_user_records_array)
  end
  
  
  def deleteList(list_id, uuid)
    logger.debug("[AccountManagement] deleteList : list_id: #{list_id} uuid: #{uuid}")
    list = List.getListByIdAndUser(list_id, uuid)
    if(list.nil?)
      raise("There is no list_id = #{list_id} for user = #{uuid} ")
    else
      return List.deleteList(list_id, uuid)
    end
  end
  
  
  
  def getListById(list_id, uuid, detailed_list, notice_max, page, logs = nil)
    logger.debug("[AccountManagement] getListById : list_id: #{list_id}")
    list = List.getListById(list_id)
    
    if list.nil?
      raise "No list found"
    end
    
    if list.state == LIST_PRIVATE
      error = true
      if (INFOS_USER_CONTROL and !@info_user.nil? and list.uuid == @info_user.uuid_user)
        error = false
      elsif uuid == list.uuid
        error = false
      end
      if error
        raise "No access list"
      end
    end
    
    oc = ObjectsCount.getObjectCountById(ENUM_LIST, list_id)
    comments_count = 0
    tags_count = 0
    if (INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user == list.uuid)
      comments_count = oc.comments_count
      tags_count = oc.tags_count
    else
      comments_count = oc.comments_count_public
      tags_count = oc.tags_count_public
    end
    object_tag_struct = nil
    community_user = CommunityUsers.getCommunityUserByUuid(list.uuid);
    
    if (!logs.nil?)
      @log_management.logs(logs, list)
    end
    return FactoryList.createList(list, community_user, uuid, detailed_list, object_tag_struct, tags_count, comments_count, page, notice_max)
  end
  
  def getListsByNotice(doc_id, list_max, page)
    logger.debug("[AccountManagement] getListsByNotice : doc_id: #{doc_id}")
    
    notice = Notice.getNoticeByDocId(doc_id)
    if(notice.nil?)
      raise("[AccountManagement][getListsByNotice] There is no notice with doc_id = #{doc_id} !!")
    end
    lists = List.getListsByNotice(doc_id, list_max, page)
    lists_factories = []
    
    lists.each do |list|
      if list.nil?
        raise "No list found"
      end
      
      if list.state == LIST_PRIVATE
        error = true
        if (INFOS_USER_CONTROL and !@info_user.nil? and list.uuid == @info_user.uuid_user)
          error = false
        end
        if error
          next
        end
      end
      detailed_list = false
      object_tag_struct = nil
      community_user = CommunityUsers.getCommunityUserByUuid(list.uuid);
      if (INFOS_USER_CONTROL and !@info_user.nil? and list.uuid == @info_user.uuid_user)
        lists_factories << FactoryList.createList(list, community_user, @info_user.uuid_user, detailed_list)
      else
        lists_factories << FactoryList.createList(list, community_user, detailed_list)
      end
    end
    lists_hash = Hash.new()
    lists_hash = {:doc_id => doc_id, :title => notice.dc_title, :lists_count => lists_factories.size, :lists_factories => lists_factories}
    return lists_hash;
  end
  
  
  # Add new subscription
  def addSubscription(object_type,object_uid,uuid,mail_notification,state)
    Subscription.transaction do
      begin
        user = CommunityUsers.getCommunityUserByUuid(uuid)
        if(user.nil?)
          raise("There is no user with uuid = #{uuid}")
        end
        
        sub = Subscription.getSubscriptionByObject(object_type, object_uid, uuid)
        if(!sub.nil?)
          raise("User with uuid = #{uuid} has subscribed yet to object_uid = #{object_uid} and object_type = #{object_type} !!")
        else
          # Save subscription if object is valid
          obj = nil
          if(object_type == ENUM_NOTICE)
            obj = Notice.getNoticeByDocId(object_uid)
            if(obj.nil?)
              # create notice
              if copyNotice(object_uid)
                doc_identifier,doc_collection_id = UtilFormat.parseIdDoc(object_uid);
                if doc_identifier.blank? or doc_collection_id.blank?
                  raise("Id notice blank #{object_uid}");
                end
              else
                logger.error("[AccountManagement][AddSubscription] doc not found");
                raise("Id notice blank #{object_uid}");
              end
            end
          elsif(object_type == ENUM_RSS_FEED)
            obj = RssFeed.getRssFeedById(object_uid)
          else
            raise("Subscriptions only authorized on Notices and Rss Feeds !!")
          end
          
          sub = Subscription.saveSubscription(object_type, object_uid, uuid, mail_notification, state)
        end
        
        return sub
      rescue => e
        logger.error("[AccountManagement][addSubscription] Error : #{e.message}");
        raise e;
      end
    end
  end
  
  
  # Delete subscriptions
  def deleteSubscriptions(objects, objects_ids, uuids)
    Subscription.transaction do
      begin
        if(objects.size != objects_ids.size or objects.size != uuids.size)
          raise("objects, objects_ids and uuids must have same size - some informations miss")
        end
        Subscription.deleteSubscriptions(objects, objects_ids, uuids)
        return true
      rescue => e
        logger.error("[AccountManagement][deleteSubscriptions] error : #{e.message}")
        return false
      end
    end
  end
  
  
  # Update subscription
  def updateSubscription(object_type, object_uid, uuid, mail_notification, state)
    Subscription.transaction do
      begin
        sub = Subscription.getSubscriptionByObject(object_type, object_uid, uuid)
        if(sub.nil?)
          raise("There is no subscription on object_type = #{object_type} and object_uid = #{object_uid} for user uuid = #{uuid} !! ")
        else
          sub = Subscription.updateSubscription(sub, mail_notification, state)
          return sub
        end
      rescue => e
        logger.error("[AccountManagement][updateSubscription] Error : " + e.message)
        return false
      end
    end
  end
  
  def getAlertsForUser(uuid, max = 10, page = 1, sort = SORT_DATE, direction = DIRECTION_UP)
    tab = []
    subscriptions = Subscription.getSubscriptionByTypeObject(ENUM_NOTICE, uuid, page, max, sort, direction)
    if (!subscriptions.nil?)
      arrayId = []
      subscriptions.each do |s|
        arrayId << s.object_uid
      end
      examplaires = getExamplairesByNotices(arrayId)
      subscriptions.each do |subscription|
        notice = Notice.getNoticeByDocId(subscription.object_uid)
        if (!notice.blank?)
          # get etat examplaire
          id_doc, id_collection = UtilFormat.parseIdDoc(subscription.object_uid)
          idDoc = "#{id_doc};#{id_collection}"
          ex = nil
          if (examplaires.size != 0 and examplaires.has_key?(idDoc)) 
            ex = examplaires[idDoc][:examplaires]
          end
          notice_struct = FactoryNotice.createNotice(notice, ex, uuid)
          tab << FactorySubscription.createSubscription(subscription, notice_struct)
        end
      end
    end
    return tab
  end
  
  
  def getExamplairesByNotices(notices_id_tab)
    logger.debug("[AccountManagement] [getExamplairesByNotices] : #{notices_id_tab.inspect}")
    docs_to_check = Hash.new();
    if !notices_id_tab.empty?
      notices_id_tab.each do |item|
        id_doc, id_collection = UtilFormat.parseIdDoc(item)
        if id_doc.nil? or id_collection.nil?
          raise "error"
        end
        if !docs_to_check.has_key?(id_collection)
          docs_to_check[id_collection] = []
        end
        docs_to_check[id_collection] << id_doc
      end
    end
    logger.debug("docs_to_check : #{docs_to_check.inspect}")
    # Get examplaires from distant DB as Hash
    return PortfolioSearchClass.getExamplairesForNotices(docs_to_check)
  end
  
  # Method getProfile : getProfile menu for uuid
  def getProfile(uuid, log)
    
    cu = CommunityUsers.getCommunityUserByUuid(uuid)
    logger.debug("[AccountManagement][getProfile] User #{uuid} found ")
    if cu.nil?
      raise("There is no user with uuid = #{uuid}")
    end
    
    user_lists = []
    user_tags = []
    detailed_list = false
    if (INFOS_USER_CONTROL and !@info_user.nil? and @info_user.uuid_user == uuid)
      state_tag = nil
      state_list = nil
      user = uuid
    else
      state_tag =  TAG_PUBLIC
      state_list = LIST_PUBLIC
      user = nil
    end
    
    lists = List.getListByUser(uuid, state_list)
    # Generate users_lists
    lists.each do |li|
      if(!li.nil?)
        user_lists << FactoryList.createList(li, cu, user, detailed_list)
      end
    end
    
    tag_weight = 0
    
    # Get User Tags with owner
    tags = Tag.getTagsByUser(uuid, state_tag)
    tags.each do |ta|
      if(!ta.nil?)
        user_tags << FactoryTag.createTag(ta, tag_weight)
      end
    end
    user_pref = UsersPreferences.find(:first, :conditions => "uuid='#{uuid}'")
    profile = FactoryProfile.createProfile(cu, user_lists, user_tags, user_pref, user)
    
    if (log and !cu.nil?)
      @log_management.addLogRebonceProfil(cu)
    end
    
    return profile
  end
  
  
  def getNoticesToCheckAvailability(collection_id)
    begin
      notices_ids = []
      subscriptions = Subscription.getNoticesToCheckAvailability(collection_id)
      subscriptions.each do |sub|
        notices_ids << sub.dc_identifier
      end
      return notices_ids
    rescue => e
      logger.error("[AccountManagement][getNoticesToCheckAvailability] Error : " + e.message)
      return false
    end    
  end
  
  def saveHistorySearch(tab_filter, search_input, search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id, context)
    begin
      
      rh = HistorySearch.findHistorySearch(tab_filter, search_input,search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id)
      if(rh.nil?)
        rh = HistorySearch.saveHistorySearch(tab_filter, search_input,search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id)
      end
      
      @log_management.addLogSearch(rh.id, theme_id, context)
      
      return rh.id
    rescue => e
      logger.error("[AccountManagement][saveHistorySearch] Error : " + e.message)
      raise e
    end
  end
  
  def saveUserHistorySearches(uuid, history_searches)
    HistorySearch.transaction do
      begin
        community_user = CommunityUsers.getCommunityUserByUuid(uuid)
        if(community_user.nil?)
          raise("[AccountManagement][saveUserSearch] There is no user with uuid = #{uuid} !!")
        end
        history_searches.each do |id_history_search, jobs|
          if (id_history_search.blank?)
            raise "no history"
          end
          id_history_search = id_history_search.to_i
          
          results_count = 0
          if (jobs)
            total_hits = JobQueue.total_hits_by_jobs(jobs)
            if !total_hits.nil?
              total_hits.each do |r|
                if (!r.nil? and !r[:total_hits].nil?)
                  results_count += r[:total_hits]
                end
              end
            end
          end  
          
          history_search = HistorySearch.getHistorySearch(id_history_search)
          if(history_search.nil?)
            logger.warn("No history search with id = #{id_history_search}")
          else
            user_history_search = UsersHistorySearch.saveUserHistorySearch(uuid, results_count, id_history_search)
            
            @log_management.addLogSaveRequest(user_history_search.id)
          end
        end
        return true
      rescue => e
        logger.error("[AccountManagement][saveUserHistorySearch] Error : " + e.message)
        raise e
      end
    end
  end
  
  def deleteUserHistorySearches(user_searches_ids)
    begin
      uuid = nil
      if (INFOS_USER_CONTROL and !@info_user.nil?)
        uuid = @info_user.uuid_user
      end
      UsersHistorySearch.deleteUserHistorySearches(user_searches_ids, uuid)
      return true
    rescue => e
      logger.error("[AccountManagement][deleteUserSearches] Error : " + e.message)
      raise e
      
    end
  end
  
  def deleteHistorySearch(history_search_ids)
    begin
      HistorySearch.deleteHistorySearch(history_search_ids)
      return true
    rescue => e
      logger.error("[AccountManagement][deleteHistorySearch] Error : " + e.message)
      raise e
    end
  end
  
  def getUserSearchesHistory(uuid, max, page, sort, direction)
    begin
      community_user = CommunityUsers.getCommunityUserByUuid(uuid)
      if(community_user.nil?)
        raise("There is no user with uuid = #{uuid} !!")
      end
      history = HistorySearch.getUserSearchesHistory(uuid, max, page, sort, direction)
      return history;
    rescue => e
      logger.error("[AccountManagement][getUserSearchesHistory] Error : " + e.message)
      raise e
    end
  end
  
  def saveUserParams(uuid, params, desc)
    begin
      CommunityUsers.transaction do
        community_user = CommunityUsers.getCommunityUserByUuid(uuid)
        if(community_user.nil?)
          raise("[AccountManagement][saveUserParams] There is no user with uuid = #{uuid} !!")
        end
        logger.debug("[AccountManagement][saveUserParams] params reçus : #{params}")
        p = ActiveSupport::JSON.decode(params)
        if (!p.nil? && !p.empty?)
          logger.debug("[AccountManagement][saveUserParams]  pseudo : #{p['pseudo']} et description : #{p['description']}")
          community_user = CommunityUsers.updateUserInfos(community_user, p['pseudo'], p['description'], desc)
          UsersPreferences.updateAll(uuid, p)
          if (!p['search_preferences'].blank?)
            search_prefs = ActiveSupport::JSON.decode(p['search_preferences'])
            search_prefs.each do |onglet, filtersgroups|             
              st = SearchTab.find(:first , :select => "id", :conditions => ["label = ?", onglet])
              UsersTabsSearchesPreferences.saveUserTabSearchPreferences(uuid, st.id.to_s, filtersgroups['group'], filtersgroups['filter'])
            end
          end
        end
        return community_user;
      end
    rescue => e
      logger.error("[AccountManagement][updateUserInfos] Error : " + e.message)
      raise e
    end
  end
  
  def getRssFeeds(new_docs, isbn_issn_not_null, collection_group)
    begin
      rss_feeds = RssFeed.getRssFeeds(new_docs, isbn_issn_not_null, collection_group)
      
      return rss_feeds
    rescue => e
      logger.error("[AccountManagement][getUserParameters] Error : " + e.message)
      raise e
    end    
  end
  
  def deleteAllAlerts(uuid)
    begin 
      Subscription.deleteAllAlerts(uuid)
      
      return true
    rescue => e
      logger.error("[AccountManagement][deleteAllAlerts] Error : " + e.message)
      raise e
    end
  end
  
  def deleteCommentAlerted(comment_id)
    begin
      Comment.transaction do 
        comment = Comment.find(comment_id)
        if (comment.nil?)
          raise "no comment"
        end
        
        user = comment.community_users
        
        Comment.unvalidateComment(comment_id)
        CommentsAlert.deleteCommentsAlert(comment_id)
        
        # Send mail to library find administrator
        subject = translate("SUBJECT_COMMENT_ALERT_DELETE", nil, nil, "mail")
        message = translate("BODY_COMMENT_ALERT_DELETE", [comment.content], nil, "mail")
        Emailer.generateMail([user.uuid, LIBRARYFIND_EMAIL_USER], subject, message)
        
        return true
      end
    rescue => e
      logger.error("[AccountManagement][deleteCommentAlerted] Error : " + e.message)
      raise e
    end
  end
  
  def deleteAlertsOnComment(comment_id)
    begin
      CommentsAlert.deleteCommentsAlert(comment_id)
      return true
    rescue => e
      logger.error("[AccountManagement][deleteCommentAlerted] Error : " + e.message)
      raise e
    end
  end
  
  def notifyAllByMail(uuid)
    begin
      Subscription.notifyAllByMail(uuid)
      
      return true
    rescue => e
      logger.error("[AccountManagement][notifyAllByMail] Error : " + e.message)
      raise e
    end
  end
  
  def getUserPrivacyParameters(uuid)
    begin
      community_user = CommunityUsers.getCommunityUserByUuid(uuid)
      if(community_user.nil?)
        raise("There is no user with uuid = #{uuid} !!")
      end
      
      user_preferences = nil
      user_preferences = UsersPreferences.getUserPrivacyParameters(uuid)
      
      user_tabs_searches_preferences = []
      
      user_tabs_searches = UsersTabsSearchesPreferences.getUserTabsSearches(uuid)
      
      user_tabs_searches.each do |uts|
        user_tabs_searches_preferences << FactorySearchesParameters.createSearchesParameters(uts)
      end
      
      user_parameters = FactoryUserParameters.createFactoryUserPrivacyParameters(community_user, user_preferences, user_tabs_searches_preferences)
      
      return user_parameters
    rescue => e
      logger.error("[AccountManagement][getUserPrivacyParameters] Error : " + e.message)
      raise e
    end
  end
  
  ############################
  # AddLogCart
  ############################
  
  def addLogCarts(notices, first)
    return @log_management.addLogCarts(notices, first)
  end
  
  ############################
  # AddLogFacette
  ############################
  
  def addLogFacette(types)
    return @log_management.addLogFacette(types)
  end  
  
  def addLogConsultRessource(notice_id, indoor)
    if !notice_id.blank?
      doc_identifier, collection_id = UtilFormat.parseIdDoc(notice_id);
      return @log_management.addLogConsultRessource(doc_identifier, collection_id, indoor)
    end  
  end
  
end