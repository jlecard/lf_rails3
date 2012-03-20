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
class Admin::LogViewGenericController < ApplicationController
  include ApplicationHelper
  include Admin::LogViewGenericHelper
  
  layout 'admin'
  before_filter :authorize, :except => 'login',
  :role => 'administrator', 
  :msg => 'Access to this page is restricted.'
  
  SEPARATOR = ","
  ENDLINE = "\n"
  
  def initialize
    super
    @search_tabs = SearchTab.find(:all)
    @profiles = ManageRole.find(:all)

  end
  
  def index
  end
  
  def requests

    case params[:mode]
      when "c"
      @group_collections = CollectionGroup.find(:all)
      @title = "Nombre de requetes sur chaque couple d'index"
      method = "couple_request"
      @headers = ["tab_filter","search_group", "search_type_label", "date", "total"]
      when "t"
      @group_collections = CollectionGroup.find(:all)
      @title = "Liste les requetes les plus frequentes"
      method = "list_most_search_popular"
      @headers = ["search_input", "search_type_label", "search_group", "tab_filter", "date","total"]
      when "n"
      @search_tabs_subjects = SearchTabSubject.find(:all)
      @title = "Nombre de clics sur chacun des liens lançant une requete préprogrammée"
      method = "search_theme"
      @headers = ["search_tab_subject_id","date","total"]
      when "s"
      @title = "Nombre de clics sur le lien \"Voir Aussi\""
      method = "see_also"
      @headers = ["tab_filter","date","total"]
      when "r"
      @title = "Nombre de requetes via des rebonds"
      method = "rebonce"
      @headers = ["tab_filter","date","total"]
      when "sp"
      @title = "Nombre de requetes via le correcteur orthographique"
      method = "spell"
      @headers = ["tab_filter","date","total"]
    else
      @title = "Nombre total de requetes"
      params[:mode] = "all"
      method = "total_request"
      @headers = ["tab_filter","date","total"]
    end
    
    classe = "LogSearch"
    generic(classe, method)
    
  end
  
  def carts
    
    case params[:mode]
      when "s"
      @group_collections = CollectionGroup.find(:all)
      @title = "Nombre de notices sauvegardées dans les paniers"
      method = "doc_save_in_cart"
      @headers = ["profil","date","total"]
    else
      params[:mode] = "f"
      @title = "Nombre de paniers utilisés"
      @headers = ["profil","date","total"]
      method = "cart_use"
    end
    
    classe = "LogCartUsage"
    generic(classe, method, true)
  end
  
  def consult
    @types = nil
    case params[:mode]
      when "p"
      @title = "Nombre de notices imprimées"
      @headers = ["profil","date","total"]
      method = "print_notice"
      when "e"
      @title = "Nombre de notices envoyées par email"
      @headers = ["profil","date","total"]
      method = "email_notice"
      when "pdf"
      @title = "Nombre de notices générées en pdf"
      @headers = ["profil","date","total"]
      method = "pdf_notice"
      when "cc"
      @title = "Nombre de notices consultées par collection"
      @headers = ["collection_name","date","total"]
      method = "consult_notice_by_collection"
      when "top"
      @types = LogConsult.get_material_type()
      @title = "Top notice consultées"
      @headers = ["idDoc", "collection_id", "alt_name", "title", "material_type", "date", "total", ]
      method = "top_consulted"
      when "export"
      @title = "Nombre de notices exportées"
      @headers =  ["context", "date","total"]
      method = "export_notice"
    else
      params[:mode] = "c"
      @title = "Nombre de notices consultées"
      @headers = ["profil","date","total"]
      method = "consult_notice"
    end
    
    classe = "LogConsult"
    generic(classe, method, true)
  end
  
  def document
    
    params[:mode] = "d"
    @title = "Nombre de documents consultés"
    @headers = ["collection_name", "indoor", "date","total"]
    method = "consult_ressource"
    
    classe = "LogConsultRessource"
    generic(classe, method, true)
  end
  
  def save_notice
    case params[:mode]
      when "l"
      @title = "Nombre de notices sauvegardées dans des listes"
      @headers = ["profil", "date","total"]
      method = "notice_save_in_list"
      when "m"
      @title = "Nombre de notices sauvegardées des Mes documents"
      @headers = ["profil", "date","total"]
      method = "notice_save_mydoc"
    else
      params[:mode] = "s"
      @title = "Nombre de notices sauvegardées"
      @headers = ["profil", "date","total"]
      method = "notice_save_total"
    end
    
    classe = "LogSaveNotice"
    generic(classe, method, true)
  end
  
  def tag
    case params[:mode]
      when "dt"
      @title = "Nombre de mots clés supprimés"
      @headers = ["date","total"]
      method = "tag_delete"
      when "cn"
      @title = "Nombre de mots clés crées sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "tag_create_by_notice"
      when "dn"
      @title = "Nombre de mots clés supprimés sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "tag_delete_by_notice"
      when "cl"
      @title = "Nombre de mots clés crées sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "tag_create_by_liste"
      when "dl"
      @title = "Nombre de mots clés supprimés sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "tag_delete_by_liste"
    else
      params[:mode] = "ct"
      @title = "Nombre de mots clés crées"
      @headers = ["date","total"]
      method = "tag_create"
    end
    
    classe = "LogTag"
    generic(classe, method, true)
  end
  
  def comment
    case params[:mode]
      when "dt"
      @title = "Nombre de commentaires supprimés"
      @headers = ["date","total"]
      method = "comment_delete"
      when "cn"
      @title = "Nombre de commentaires crées sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "comment_create_by_notice"
      when "dn"
      @title = "Nombre de commentaires supprimés sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "comment_delete_by_notice"
      when "cl"
      @title = "Nombre de commentaires crées sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "comment_create_by_liste"
      when "dl"
      @title = "Nombre de commentaires supprimés sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "comment_delete_by_liste"
    else
      params[:mode] = "ct"
      @title = "Nombre de commentaires crées"
      @headers = ["date","total"]
      method = "comment_create"
    end
    
    classe = "LogComment"
    generic(classe, method, true)
  end
  
  def note
    case params[:mode]
      when "dt"
      @title = "Nombre de notes supprimées"
      @headers = ["date","total"]
      method = "note_delete"
      when "cn"
      @title = "Nombre de notes créees sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "note_create_by_notice"
      when "dn"
      @title = "Nombre de notes supprimées sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "note_delete_by_notice"
      when "cl"
      @title = "Nombre de notes créees sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "note_create_by_liste"
      when "dl"
      @title = "Nombre de notes supprimées sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "note_delete_by_liste"
    else
      params[:mode] = "ct"
      @title = "Nombre de notes créees"
      @headers = ["date","total"]
      method = "note_create"
    end
    
    classe = "LogNote"
    generic(classe, method, true)
  end
  
  def list_consult
    case params[:mode]
      when "v"
      @title = "Nombre de consultation de liste"
      @headers = ["date","total"]
      method = "total_liste_consult"
      when "vl"
      @title = "Nombre de consultation par liste"
      @headers = ["liste_id", "title", "date","total"]
      method = "total_consult_by_list"
      when "d"
      @title = "Nombre de liste supprimée"
      @headers = ["notice_id", "date","total"]
      method = "total_liste_delete"
    else
      params[:mode] = "c"
      @title = "Nombre de liste créee"
      @headers = ["date","total"]
      method = "total_liste_create"
    end
    
    classe = "LogListConsult"
    generic(classe, method, true)
    
  end
  
  def save_request
    case params[:mode]
      when "c"
      # other case
    else
      params[:mode] = "s"
      @title = "Nombre de requêtes sauvegardées"
      @headers =  ["profil", "date","total"]
      method = "save_request"
    end
    
    classe = "LogSaveRequest"
    generic(classe, method, true)
  end
  
  
  def rebonce_tag
    case params[:mode]
      when "n"
      @title = "Nombre de rebonds sur les mots clés via une notice"
      @headers = ["tag_label", "date","total"]
      method = "by_notice"
      when "l"
      @title = "Nombre de rebonds sur les mots clés via une liste"
      @headers = ["tag_label", "date","total"]
      method = "by_liste"
    else
      params[:mode] = "all"
      @title = "Nombre de rebonds sur les mots clés"
      @headers = ["tag_label", "date","total"]
      method = "total"
    end
    
    classe = "LogRebonceTag"
    generic(classe, method, true)
  end
  
  def rebonce_profil
    case params[:mode]
      when "n"
      # other case
    else
      params[:mode] = "all"
      @title = "Nombre de rebonds sur les profils"
      @headers = ["name","uuid", "date","total"]
      method = "rebonce"
    end
    
    classe = "LogRebonceProfil"
    generic(classe, method, true)
  end
  
  def rebonce_liste
    case params[:mode]
      when "n"
      # other case
    else
      params[:mode] = "all"
      @title = "Nombre de rebonds sur les listes"
      @headers = ["liste_id", "title", "date","total"]
      method = "total_consult_by_list"
    end
    
    classe = "LogListConsult"
    generic(classe, method, true)
  end
  
  def facette
    case params[:mode]
      when "c"
      # other case
    else
      params[:mode] = "s"
      @title = "Nombre d'action sur les facettes"
      @headers =  ["facette", "date","total"]
      method = "facette"
    end
    
    classe = "LogFacetteUsage"
    generic(classe, method, true)
  end
  
  def top_notice
    
    params[:max] = extract_param("max", Integer, 5);
    params[:page] = extract_param("page", Integer, 1);
    
    is_export = export_csv?()
    
    case params[:mode]
      when "comment"
      @title = "Les notices les plus commentés"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "comments_count", "comments_count_public"]
      results = Notice.topByComment(params[:page], params[:max])
      
      when "tag"
      @title = "Les notices les plus taggées"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "tags_count", "tags_count_public"]
      results = Notice.topByTag(params[:page], params[:max])
      
      when "liste"
      @title = "Les notices les plus dans les listes"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "lists_count", "lists_count_public"]
      results = Notice.topByListe(params[:page], params[:max])
      
      when "sub"
      @title = "Les notices les plus attendues"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "subscriptions_count"]
      results = Notice.topBySubscription(params[:page], params[:max])
      
      when "export"
      @title = "Les notices les plus exportées"
      @headers = ["idDoc", "collection_id", "alt_name", "title", "material_type", "date","total"]
      method = "topExport"
      generic("LogConsult", method, true)
      return
    else
      params[:mode] = "note"
      @title = "Les notices les mieux notées"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type","notes_avg", "notes_count"]
      results = Notice.topByNote(params[:page], params[:max])
    end
    
    if (!results.nil?)
      @items = results[:result]
      total = results[:count].to_i
      page = results[:page].to_i
      max = results[:max].to_i
    else
      @items = []
      total = 0
      page = 1
      max = 10
    end
    
    if (is_export)
      export_csv
    else
      @pages = Paginator.new self, total, max, page
    end
  end
  
  def top_liste
    
    params[:max] = extract_param("max", Integer, 5);
    params[:page] = extract_param("page", Integer, 1);
    
    is_export = export_csv?()
    
    case params[:mode]
      when "comment"
      @title = "Les notices les plus commentés"
      @headers =  ["id","title","comments_count", "comments_count_public"]
      results = List.topByComment(params[:page], params[:max])
      when "notice"
      @title = "Les listes avec le plus de notices"
      @headers =  ["id","title","notices_count"]
      results = List.topByNotice(params[:page], params[:max])
      when "tag"
      @title = "Les listes les plus taggées"
      @headers =  ["id","title","tags_count", "tags_count_public"]
      results = List.topByTag(params[:page], params[:max])
      when "liste"
      @title = "Les listes les plus dans les listes"
      @headers =  ["id","title","lists_count", "lists_count_public"]
      results = List.topByListe(params[:page], params[:max])
    else
      params[:mode] = "note"
      @title = "Les listes les mieux notées"
      @headers =  ["id","title","notes_avg", "notes_count"]
      results = List.topByNote(params[:page], params[:max])
    end
    
    if (!results.nil?)
      @items = results[:result]
      total = results[:count].to_i
      page = results[:page].to_i
      max = results[:max].to_i
    else
      @items = []
      total = 0
      page = 1
      max = 10
    end
    
    if (is_export)
      export_csv
    else
      @pages = Paginator.new self, total, max, page
    end
  end
  
  private
  def generic(classe, method, by_profil=false)
    
    params[:order] = extract_param("order", String, "total");
    params[:tab_filter] = extract_param("tab_filter", String, "");
    params[:unit] = extract_param("unit", String, "");
    params[:page] = extract_param("page", Integer, 1);
    params[:max] = extract_param("max", Integer, 25);
    params[:date_from] = extract_param("date_from", String, nil);
    params[:date_to] = extract_param("date_to", String, nil);
    params[:profil] = extract_param("profil", String, "");
    
    is_export = export_csv?()
    
    profil_tab = ""
    if by_profil
      profil_tab = params[:profil]
    else
      profil_tab = params[:tab_filter]
    end
    
    mat_type = ""
    params[:material_type] = extract_param("material_type", String, "");
    if (params[:mode] == "top")
      mat_type = ",params[:material_type]"
    end
    
    results = nil
    eval("results = #{classe}.#{method}(params[:unit], params[:date_from], params[:date_to], profil_tab, params[:order],  params[:page], params[:max]#{mat_type})")
    
    if (!results.nil?)
      @items = results[:result]
      total = results[:count].to_i
      page = results[:page].to_i
      max = results[:max].to_i
    else
      @items = []
      total = 0
      page = 1
      max = 10
    end
    
    if (is_export)
      export_csv
    else
      @pages = Paginator.new self, total, max, page
    end
  end
  
  def export_csv?
    params[:export] = extract_param("export", String, nil);
    
    if (!params[:export].blank?)
      # export tout
      params[:max] = 999999
      params[:page] = 1
      return true
    end
    
    return false
  end
  
  def export_csv
    datas = ""
    h_translate = []
    @headers.each do |h|
      h_translate << verify_write(translate(h))
    end
    datas += h_translate.join(SEPARATOR)
    datas += ENDLINE
    
    size_h = @headers.size()
    
    @items.each do |i|
      cpt = 1
      @headers.each do |he|
        
        case he
          
          when "date"
          if !params[:unit].blank?
            datas += verify_write(format_date_stats(i))
          else
            datas += ""
          end
          
          when "indoor"
          if i[he] == "0"
            datas += verify_write(translate("l_outdoor"))
          else
            datas += verify_write(translate("l_indoor"))
          end
          
          when "facette"
          datas += verify_write(translate(i[he]))
          
          when "search_group"
          datas += verify_write(get_label_gc(@group_collections, i[he]))
          
          when "search_tab_subject_id"
          datas += verify_write(get_label_search_tab_subject(@search_tabs_subjects, i[he]))
          
        else
          datas += verify_write("#{i[he]}")
        end
        
        if cpt < size_h
          datas += SEPARATOR
        else
          datas += ENDLINE
        end
        cpt += 1
      end
    end
    
    send_data(datas, :filename=>"#{@title}.csv")
  end
  
  def verify_write(data)
    if data.nil?
      return ""
    end
    return data.gsub(SEPARATOR,"").gsub(ENDLINE, "")
  end
  
end