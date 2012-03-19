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

class AccountDispatch < DispatchAbstract
  
  def driver
    logger.debug("LibraryFind: " + ::LIBRARYFIND_WSDL.to_s)
    
    case LIBRARYFIND_WSDL
      when LIBRARYFIND_WSDL_ENGINE
      require 'soap/wsdlDriver'
      driver = SOAP::WSDLDriverFactory.new(LIBRARYFIND_WSDL_HOST).create_rpc_driver
      return driver
    else
      m = AccountManagement.new()
      m.setInfosUser(@info_users)
      return m
    end
  end
  
  
  def saveNoticesByUser(id_notices, uuid)
    objdriver = driver
    objdriver.send :saveNoticesByUser, id_notices, uuid
  end
  
  
  def deleteUserRecordsByUser(id_notices, uuid)
    objdriver = driver
    objdriver.send :deleteUserRecordsByUser, id_notices, uuid
  end
  
  
  def getUserRecordsByUser(uuid, max, page, sort, direction)
    objdriver = driver
    objdriver.send :getUserRecordsByUser, uuid, max, page, sort, direction
  end
  
  
  def saveOrUpdateList(list_id, title, ptitle, uuid, description,state)
    objdriver = driver
    objdriver.send :saveOrUpdateList, list_id, title, ptitle, uuid, description, state
  end
  
  
  def changeStateList(list_id, uuid, state, datePublic=nil, dateEndPublic=nil)
    objdriver = driver
    objdriver.send :changeStateList, list_id, uuid, state, datePublic, dateEndPublic
  end
  
  
  def downNoticeInList(list_id, user_record, max)
    objdriver = driver
    objdriver.send :downNoticeInList, list_id, user_record, max
  end
  
  
  def upNoticeInList(list_id, user_record)
    objdriver = driver
    objdriver.send :upNoticeInList, list_id, user_record
  end
  
  
  def addNoticesToList(list_id, uuid, id_notices)
    objdriver = driver
    objdriver.send :addNoticesToList, list_id, uuid, id_notices
  end
  
  
  def addUserRecordsToList(list_id, uuid, user_records_array)
    objdriver = driver
    objdriver.send :addUserRecordsToList, list_id, uuid, user_records_array
  end
  
  
  def deleteListUserRecords(list_id, uuid, list_user_records_array)
    objdriver = driver
    objdriver.send :deleteListUserRecords, list_id, uuid, list_user_records_array
  end
  
  
  def deleteList(list_id, uuid)
    objdriver = driver
    objdriver.send :deleteList, list_id, uuid
  end
  
  def getListById(list_id, uuid, detailed_list, notice_max, page, logs = nil)
    objdriver = driver
    objdriver.send :getListById, list_id, uuid, detailed_list, notice_max, page, logs
  end
  
  
  def getListsByNotice(doc_id, list_max, page)
    objdriver = driver
    objdriver.send :getListsByNotice, doc_id, list_max, page
  end
  
  
  def addSubscription(object,object_id,uuid,mail_notification, state)
    objdriver = driver
    objdriver.send :addSubscription, object, object_id, uuid, mail_notification, state
  end
  

  def updateSubscription(object,object_id,uuid, mail_notification, state)
    objdriver = driver
    objdriver.send :updateSubscription, object, object_id, uuid, mail_notification, state
  end
  
  def deleteSubscriptions(objects,objects_ids,uuids)
    objdriver = driver
    objdriver.send :deleteSubscriptions, objects,objects_ids,uuids
  end  

  def getProfile(uuid, log)
    objdriver = driver
    objdriver.send :getProfile, uuid, log
  end
  
  def saveHistorySearch(tab_filter, search_input, search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id, context)
    objdriver = driver
    objdriver.send :saveHistorySearch, tab_filter, search_input, search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id, context
  end
  
  def saveUserHistorySearches(uuid, history_searches)
    objdriver = driver
    objdriver.send :saveUserHistorySearches, uuid, history_searches
  end
  
  def deleteUserHistorySearches(user_searches_ids)
    objdriver = driver
    objdriver.send :deleteUserHistorySearches, user_searches_ids
  end
  
  def deleteHistorySearch(history_search_ids)
    objdriver = driver
    objdriver.send :deleteHistorySearch, history_search_ids
  end
  
  def getUserSearchesHistory(uuid, max, page, sort, direction)
    objdriver = driver
    objdriver.send :getUserSearchesHistory, uuid, max, page, sort, direction
  end
  
  def getAlertsForUser(uuid, max, page, sort, direction)
    objdriver = driver
    objdriver.send :getAlertsForUser, uuid, max, page, sort, direction
  end

  def SaveUserParams(uuid, params, desc)
    objdriver = driver
    objdriver.send :saveUserParams, uuid, params, desc
  end
  
  def deleteAllAlerts(uuid)
    objdriver = driver
    objdriver.send :deleteAllAlerts, uuid
  end
  
  def deleteCommentAlerted(comment_id)
    objdriver = driver
    objdriver.send :deleteCommentAlerted, comment_id
  end
  
  def deleteAlertsOnComment(comment_id)
    objdriver = driver
    objdriver.send :deleteAlertsOnComment, comment_id
  end
  
  def notifyAllByMail(uuid)
    objdriver = driver
    objdriver.send :notifyAllByMail, uuid
  end
  
  def getUserPrivacyParameters(uuid)
    objdriver = driver
    objdriver.send :getUserPrivacyParameters, uuid
  end
  
  #=================================================
  # CARTS 
  #=================================================
  def addLogCarts(notices, first)
    objdriver = driver
    objdriver.send :addLogCarts, notices, first
  end
  
  #=================================================
  # FACETTE
  #=================================================
  
  def addLogFacette(types)
    objdriver = driver
    objdriver.send :addLogFacette, types
  end
  
  def addLogConsultRessource(notice_id, indoor)
    objdriver = driver
    objdriver.send :addLogConsultRessource, notice_id, indoor
  end
  
  
end