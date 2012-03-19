# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
class Admin::ExportstatsController < ApplicationController

  def index
  end


  def exportCSVCart
#    log = LogCartUsage.new
#    consults = log.logCart(25)
#    
#    datas = "Year,Month,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVCart.csv")
  end
  

  def exportCSVRss
#    log = LogRssUsage.new
#    consults = log.logRss(25)
#    
#    datas = "Year,Month,Used\n"
#    
#    consults.each do |key1, value1|
#      value1.each do |key2, value2|
#        datas += "#{key1},#{key2},#{value2}\n"
#      end
#    end
#
#    send_data(datas, :filename=>"ExportCSVRss.csv")
  end
  

  def exportCSVPrint
#    log = LogPrintUsage.new
#    consults = log.logPrinted(25)
#    
#    datas = "Year,Month,Used\n"
#    
#    consults.each do |key1, value1|
#      value1.each do |key2, value2|
#        datas += "#{key1},#{key2},#{value2}\n"
#      end
#    end
#
#    send_data(datas, :filename=>"ExportCSVPrints.csv")
  end


  def exportCSVMail
#    log = LogMailUsage.new
#    consults = log.logMailed(25)
#    
#    datas = "Year,Month,Used\n"
#    
#    consults.each do |key1, value1|
#      value1.each do |key2, value2|
#        datas += "#{key1},#{key2},#{value2}\n"
#      end
#    end
#
#    send_data(datas, :filename=>"ExportCSVMails.csv")
  end
  
  
  def exportCSVConsult
#    log = LogConsult.new
#    consults = log.logConsulted(25)
#    
#    datas = "Collection,Id,Title\n"
#    consults.each do |item|
#      tmp = item.split(ID_SEPARATOR)
#      datas += "#{tmp[0]},#{tmp[1]},#{item.title}\n"
#    end
#    send_data(datas, :filename=>"ExportCSVConsults.csv")
  end


  def exportCSVStatWithChart
#    log = eval("#{params[:className]}.new")
#    itemsQty = log.getDatasQty
#    itemsPc = log.getDatasPc
#    
#    dataQty = Hash.new
#    itemsQty.each do |name, qty|
#      if not qty == 0
#        dataQty["#{name}"] = "#{qty}"
#      end
#    end
#
#    dataPc = Hash.new
#    itemsPc.each do |name, pc|
#      dataPc["#{name}"] = "#{pc}"
#    end
#
#    datas = "Identifier,Quantity,Percent\n"
#    dataQty.each do |name, qty|
#      tmpName = name.gsub(/,/,' -')
#      datas += "#{tmpName},#{qty},#{dataPc[name]}\n"
#    end
#    send_data(datas, :filename=>"ExportCSV#{params[:fileName]}.csv")
  end
  
  def exportCSVWord
#    log = LogSearchWord.new();
#    word = log.logWord();
#    
#    datas = "Word,Recurrence,Nombre de resultat retourne\n"
#    word.each do |item|
#      datas += "#{item[0]},#{item[1]},#{item[2]}\n"
#    end
#    send_data(datas, :filename=>"ExportCSVWord.csv")
  end
  
  def exportCSVMailExport
#    log = LogMailExport.new
#    consults = log.logExport()
#    
#    datas = "Year,Month,types of exportations,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.object_type},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVMailExport.csv")
  end
  
  def exportCSVPrints
#    log = LogPrint.new
#    consults = log.log_p()
#    
#    datas = "Year,Month,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVPrints.csv")
  end
  
  def exportCSVListCons
#    log = LogListConsult.new
#    consults = log.logList()
#    
#    datas = "Year,Month,Title,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.title},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVListCons.csv")
  end
  
  def exportCSVRebonceTag
#    log = LogRebonceTag.new
#    consults = log.log_rebTag()
#    
#    datas = "Year,Month,Type,Notices,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.mode},#{item.uuid},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVRebonceTag.csv")
  end
  
  def exportCSVRebonceMode
#    log = LogRebonceMode.new
#    consults = log.log_rm()
#    
#    datas = "Year,Month,Type,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.mode},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVRebonceMode.csv")
  end
  
  def exportCSVFacet
#    log = LogFacetteUsage.new
#    consults = log.facet()
#    
#    datas = "Year,Month,Type,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.types},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVFacet.csv")
  end
  
  def exportCSVSaverequest
#    log = LogSaveRequest.new
#    consults = log.req()
#    
#    datas = "Year,Month,input1,input2,input3,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.search_input},#{item.search_input2},#{item.search_input3},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVSaveRequest.csv")
  end

  def exportCSVTag
#    log = LogTag.new
#    consults = log.taggue()
#    
#    datas = "Year,Month,types,documents,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.object_type},#{item.uuid},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVTag.csv")
  end
  
  def exportCSVCommentNote
#    log = LogComment.new
#    consults = log.CommentNote()
#    
#    datas = "Year,Month,types,documents,Notes,Used\n"
#    
#    consults.each do |item|
#      datas += "#{item.year},#{item.month},#{item.object_type},#{item.object_uid},#{item.note},#{item.count}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVCommentNote.csv")
  end
  
  def exportCSVHistorySearch
#    log = HistorySearch.new
#    consults = log.query()
# 
#    datas = "search_input1, search_group, tab_filter, search_operator1, search_input2, search_operator2, search_input3\n"
#    
#    consults.each do |item|
#      datas += "#{item.search_input},#{item.search_group},#{item.tab_filter},#{item.search_operator1}, #{item.search_input2},#{item.search_operator2},#{item.search_input3}\n"
#    end
#
#    send_data(datas, :filename=>"ExportCSVHistorySearch.csv")
 
  end

end