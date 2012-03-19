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
class LogManagement < CommunityController
  
  def setInfosUser(infoUser)
    @infoUser = infoUser
  end
  
  # params : logs = {}
  # log_action : pdf, email, print, export_SERVICE (bibtex..), consult, rebond
  # log_cxt : search, liste, notice, basket, account, comment, tag 
  
  def logs(logs, obj = nil)
    if (!logs.nil?)
      
      logger.debug("[LogManagement] logs : #{logs.inspect}")
      log_action = logs[:log_action]
      log_cxt = logs[:log_cxt]
      
      if (!log_action.blank? and !log_cxt.blank?)
        
        case log_cxt
          when "search"
          addLogConsult(logs, obj)
          when "liste"
            if (log_action == "consult")
              addLogListConsult(obj)
            elsif (log_action != "")
              addLogConsult(logs, obj)
            end
          when "notice"
          addLogConsult(logs, obj)
          when "basket"
          addLogConsult(logs, obj)
          when "account"
          addLogConsult(logs, obj)
          when "comment"
          
          when "tag"
            if log_action == "rebond"
              tag_id = logs[:tag_id]
              object_uid = logs[:object_uid]
              object_type = logs[:object_type]
              addLogRebonceTag(tag_id, object_uid, object_type)
            end
        end
        
        if (log_action == "export")
          addLogConsult(logs, obj)
        end
      end
    end
  end
  
  def addLogSearch(search_history_id, search_tab_subject_id, context)
    # RT (requete total), RPT (requete par type)
    data = get_data()
    data[:search_history_id] = "#{search_history_id}"
    if search_tab_subject_id > 0
      data[:search_tab_subject_id] = search_tab_subject_id
    end
    data[:context] = "#{context}"
    return log("LogSearch", data)
  end
  
  #This method add a log when going on facette
  def addLogFacette(types)
    
    if (types.nil? or types.empty?)
      return false
    end
    
    # log only the last
    last = types[types.size - 1]
    if (last.nil? and types.empty?)
      return false
    end
    
    data = get_data()
    data[:facette] = "#{last[0]}"
    data[:label] = "#{last[1]}"
    return log("LogFacetteUsage", data)
  end
  
  def addLogConsultRessource(doc_identifier, collection_id, indoor)
    data = get_data()
    data[:doc_identifier] = "#{doc_identifier}"
    data[:collection_id] = collection_id
    data[:indoor] = indoor
    return log("LogConsultRessource", data)
  end
  
  #this method add a log when a notice is saved in the cart
  def addLogCarts(notices, first)
    notices.each do |id|
      data = get_data()
      data[:idDoc] = "#{id}"
      data[:first] = first
      log("LogCartUsage", data)
      first = 0
    end
    return true
  end
  
  
  #this method add a log when save a notice 
  def addLogSaveNotice(idDoc, saveIn)  
    data = get_data()
    data[:idDoc] = "#{idDoc}"
    data[:saveIn] = "#{saveIn}"
    logger.debug("[LogManagement] [addLogSaveNotice] data #{data.inspect}")
    return log("LogSaveNotice", data)
  end
  
  
  def addLogTag(tag, object_uid, object_type, int_add)
    data = get_data()
    data[:object_type] = "#{object_type}"
    data[:object_uid] = "#{object_uid}"
    data[:tag_id] = "#{tag.id}"
    data[:tag_label] = "#{tag.label}"
    data[:int_add] = int_add
    logger.debug("[AccountManagement] [addLogTag] data: #{data.inspect}")
    return log("LogTag", data)
  end
  
  def addLogComment(object_uid, object_type, int_add)
    data = get_data()
    data[:object_type] = "#{object_type}"
    data[:object_uid] = "#{object_uid}"
    data[:int_add] = int_add
    logger.debug("[AccountManagement] [addLogComment] data: #{data.inspect}")
    return log("LogComment", data)
  end
  
  def addLogNote(object_type, object_uid, note, int_add)
    data = get_data()
    data[:object_type] = "#{object_type}"
    data[:object_uid] = "#{object_uid}"
    data[:note] = note
    data[:int_add] = int_add
    logger.debug("[AccountManagement] [addLogNote] data: #{data.inspect}")
    return log("LogNote", data)
  end
  
  def addLogSaveRequest(search_history_id)
    data = get_data()
    data[:search_history_id] = "#{search_history_id}"
    logger.debug("[AccountManagement] [addLogSaveRequest] data: #{data.inspect}")
    return log("LogSaveRequest", data)
  end
  
  def addLogRebonceTag(tag_id, object_uid, object_type)
    data = get_data()
    data[:tag_id] = "#{tag_id}"
    data[:object_type] = "#{object_type}"
    data[:object_uid] = "#{object_uid}"
    logger.debug("[AccountManagement] [addLogRebonceTag] data: #{data.inspect}")
    return log("LogRebonceTag", data)
  end
  
  
  def addLogRebonceProfil(community_user)
    data = get_data()
    data[:uuid_md5] = "#{community_user.MD5}"
    logger.debug("[AccountManagement] [addLogRebonceProfil] data: #{data.inspect}")
    return log("LogRebonceProfil", data)
  end
  
  #Consultation de listes
  def addLogListConsult(liste, create_delete = nil)
    #Test : si l'utilisateur est le propriétaire de la liste : pas comptabilisé
    #if @infoUser
      #if @infoUser.uuid_user != liste.uuid
		data = get_data()
        data[:id_list] = liste.id
        data[:title] = liste.title
        data[:create_delete] = create_delete
        logger.debug("[AccountManagement] [addLogListConsult] data: #{data.inspect}")
        return log("LogListConsult", data)
      #else
        #logger.debug("[AccountManagement] [addLogListConsult] This is your list")
      #end
     #end
  end
    
  #This method add a log when rebonce
  def addLogRebonce(query, filters, host)
    logger.debug("[AccountManagement] [addLogRebonce] query: #{query} filters: #{filters} host: #{host}")
    return LogGeneric.addToFile("LogRebonceUsage", {:query => "#{query}", :filters => "#{filters}", :host => "#{host}"})  
  end
  
  #This method add a log when an RSS is taken
  def addLogRSS(rss_url, host)
    logger.debug("[AccountManagement] [addLogRSS] rss_url: #{rss_url} host: #{host}")
    return LogGeneric.addToFile("LogRSS", {:rss_url => "#{rss_url}", :host => "#{host}"})  
  end
  
  
  
  private
  
  def get_data()
    data = {}
    if (INFOS_USER_CONTROL and !@infoUser.nil?)
      data[:host] = "#{@infoUser.ip_user}"
       #data[:profil] = @infoUser.location_user
      data[:profil] = ManageRole.GetIdRoles(@infoUser).to_s
    else
      data[:host] = ""
      data[:profil] = ""
    end
    return data
  end
  
  def log(name, data)
    return LogGeneric.addToFile(name, data)  
  end
  
  private
  
  #This method add a log when going on facette
  def addLogConsult(logs, record)
    data = get_data()
    idDoc, idColl, idSearch = UtilFormat.parseIdDoc(record.id)
    data[:idDoc] = "#{idDoc}"
    data[:collection_id] = "#{idColl}"
    data[:title] = record.ptitle
    data[:material_type] = record.material_type
    data[:vendor_name] = record.vendor_name
    data[:date] = record.date
    data[:theme] = record.theme
    if (!logs.nil?)
      data[:action] = logs[:log_action]
      data[:context] = logs[:log_cxt]
    end
    return log("LogConsult", data)
  end
end
