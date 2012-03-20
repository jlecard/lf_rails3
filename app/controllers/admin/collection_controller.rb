#encoding: utf-8
# $Id: collection_controller.rb 1239 2008-03-13 16:55:13Z herlockt $

# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
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
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

class Admin::CollectionController < ApplicationController
  include ApplicationHelper
  auto_complete_for :collection, :name, {}
  auto_complete_for :collection, :alt_name, {}
  auto_complete_for :collection, :conn_type, {}
  layout 'admin'
  before_filter :authorize, :except => 'login',
  :role => 'administrator', 
  :msg => 'Access to this page is restricted.'
  
  
  # Methode pour faire la recherche du mot tapé dans le formulaire
  # params[:mot] contient le mot tapé par l'utilisateur
  # params[:parametres] contient les paramètres de connexion au service
  # params[:positions] contient la position des "&" à remettre
  # Retour : Le résultat de la recherche et les tags contenus dans la recherche séparés par le mot "hidden"
  #
  def requeteformulaire
    if ((params[:mot] != nil) && (params[:parametres] != nil) && (params[:positions] != nil))  # Si on a le bon nombre d'argument
      res = ""
      infos = reformeInformations(params[:positions],params[:parametres])  # On replace les "&" s'il y en avait
      hash = reformeHash(infos)  # On reforme la table de Hash avec les information passées en argument
      _zoom = RZOOM.new
      _items = _zoom.search(hash, ["keyword"], [params[:mot]], [], 0, 3)  # On lance la recherche du mot tapé par l'utilisateur
      longueur = 3  # On veut 3 résultats
      if _items.length < 3  # S'il y en a moins
        longueur = _items.length  # On prend le nombre de résultats obtenus
      end
      tags = ""
      if _items != []  # Si on n'a des résultats
        i=0
        string_temp = ""
        longueur.times do
          traitement = traiterResultats(_items[i].render("marc8", "utf8"))  # On appelle la méthode qui se charge de traiter les résultats
          res+=traitement[0]  # On ajoute ce traitement aux précédents 
          tags_tmp = traitement[1]  # On prend les tags qu'il y avait dans ce résultat
          tags_tmp_split = tags_tmp.split(";")  # On les sépare
          tags_split = tags.split(";")  # On sépare ceux qu'on a déjà
          intersect = tags_tmp_split & tags_split  # On fait l'intersection des deux tableaux
          diff = tags_tmp_split - intersect  # On enlève aux nouveaux tags ceux qu'il a en commun avec ceux qu'on a déjà
          if (diff != [])  # Si cette différence n'est pas nulle, ça veut dire qu'il y a des tags en plus que l'on avait pas
            tags_split = tags_split + diff  # On mémorise donc ces nouveaux tags
          end
          i+=1
          tags=tags_split.sort.join(";")  # On reforme les tags
        end  # Fin du longueur.times do
        render :text => res + "hidden #{tags}"  # Une fois les resultat formés, on renvoie les deux données séparée du mot hidden
      else  # Else du "if _items != []" On a donc aucun résultat, on l'indique donc à l'utilisateur
        render :text => "La requête n'a rien renvoyé. Veuillez essayer avec un autre mot."
      end
    else  # Else du "if ((params[:mot] != nil) && (params[:parametres] != nil) && (params[:positions] != nil))"
      render :text => "Erreur dans les paramètres de la fonction, voir le code"
    end
  end
  
  
  # Méthode pour reformer la table de hash des paramètres passés en argument sous forme de string
  # Retour : la table de hash attendue comme celle que l'on peut trouver dans une collection
  #
  def reformeHash(_params_string)
    res = Hash.new
    res["start"]=1 # C'est la valeur par défaut
    res["max"]=3 # Il ne nous en faut pas plus car il ne nous faut que quelques valeurs, que l'on à donc fixé à 3
    if _params_string != "" # S'il n'est pas vide
      _params_split = _params_string.split(",") # On sépare toutes les valeurs
      _params_split.each { |elem|
        tab = elem.split("=>") # On sépare la clé de sa valeur dans le string pour refaire la table de Hash
        if ((tab[0] == "isword") || (tab[0] == "port") || (tab[0] == "proxy") || (tab[0] == "type") || (tab[0] == "collection_id"))
          # Il faut que c'est champs soient des Int et non des String
          res[tab[0]]=tab[1].to_i
        else
          if tab[1].downcase != "vide"  # Si la valeur n'était pas vide, on met sa valeur
            res[tab[0]]=tab[1].to_s
          else
            res[tab[0]]=""  # Sinon on remet le string vide comme précédemment trouvé lors du traitement de la donnée dans le fichier _form.rhtml
          end
        end
      }
    end
    return res
  end
  
  # Methode pour replacer les "&" dans le _params_string en fonction des positions passées en argument
  # _position contient les positions des "&" sous forme "1,5,9,15"
  # _params_string contient le string dans lequel il faut remettre les "&"
  # Retour : le string reformé avec les "&" replacés
  #
  def reformeInformations(_positions,_params_string)
    res = _params_string  # On prend les paramètres
    if _positions != ""  # S'il y avait des "&" dans les paramètres
      pos_split = _positions.split(",")  # On forme le tableau des positions
      pos_split.each { |pos|  # Et pour chaque élément
        res = res.insert(pos.to_i,"&")  # On insert le "&"
      }
    end
    return res
  end
  
  # Methode pour mettre en forme le résultat de la recherche de manière à avoir une lecture fluide des résultats
  # Cette méthode fait aussi la liste des tags qui sont contenus dans le résultat
  # item contient un string qui est un résultat de la recherche
  # Retour : un tableau de 2 éléments
  #         - le premier est le résultat mis en forme pour l'affichage
  #         - le deuxième est un string qui contient tous les tags du résultat séparés pas un ";"
  #
  def traiterResultats(item)
    i = 0
    tags=""
    previous_tag=""
    item_split = item.split
    item_split.length.times do
      if item_split[i].include?("$") && i>1  # S'il y a un $ et qu'on est au moins au troisième mot
        if item_split[i-1].length>2 && item_split[i-1].to_i>0  # On regarde si le mot d'avant est un chiffre
          tag = item_split[i-1]+item_split[i].gsub("$","")+";"
          if !tags.include?(tag) # On regarde si on n'avait pas déjà le tag
            tags+=tag # On conserve son tag
          end
          previous_tag=item_split[i-1]  # On conserve le dernier tag rencontré
          item_split.insert(i-1,"<br />* ") # On ajoute un saut de ligne pour l'affichage
          i+=1  # Comme on a ajouté un élément, il faut aussi incrémenter le compteur
        else
          if item_split[i-1].length>2 && item_split[i-1].to_i==0 # Si le mot d'avant est long mais ce n'est pas un chiffre, c'est donc un mot
            tag=previous_tag+item_split[i].gsub("$","")+";"
            if !tags.include?(tag) # On regarde si on n'avait pas déjà le tag
              tags+=tag
            end
            item_split.insert(i,"<br />* #{previous_tag} ") # On ajoute le saut de ligne
            i+=1  # Comme on a ajouté un élément, il faut aussi incrémenter le compteur
          else
            tag=item_split[i-2]+item_split[i].gsub("$","")+";"  # Sinon, on va deux chiffres plus loin
            if !tags.include?(tag) # On regarde si on n'avait pas déjà le tag
              tags+=tag
            end
            previous_tag=item_split[i-2]  # On garde le tag
            item_split.insert(i-2,"<br />* ")  # On fait le saut de ligne
            i+=1  # Comme on a ajouté un élément, il faut aussi incrémenter le compteur
          end  ## Fin du item_split[i-1].length>2 && item_split[i-1].to_i==0
        end  ## Fin du item_split[i-1].length>2 && item_split[i-1].to_i>0
      end  ## Fin du item_split[i].include?("$") && i>1
      i+=1
    end
    return [(item_split.join(" ") + "<br /><br />"),tags]
  end
  
  # Méthode pour créer une paire de comboBox dont le premier contiendra les tags trouvés
  # et qui auront pour identifiant l'identifiant passé en argument
  # params[:tags] contient les tags trouvés dans les résultats
  # params[:id] contient l'identifiant des tags à créer
  # Retour : la paire de comboBox désirée
  #
  def creation
    if ((params[:tags] != nil) && (params[:id] != nil)) 
      i = 0
      res = ""
      menus="<option value=\"Vide\"></option>"
      tags = params[:tags]  # On récupère les tags trouvés lors de la recherche
      tags_split=tags.split(";")
      tags_split.length.times do
        menus+= "<option value=\"#{tags_split[i]}\">#{tags_split[i]}</option>"
        # On forme les balises avec ces tags
        i+=1
      end
        res+=getComboRecord(params[:id]).join + "<select id=\"combo_#{params[:id]}\" onchange=\"comboChange()\">" + menus + "</select>" + "<br><br>"
        # On forme les comboBox
      render :text => res  # On renvoie le résultat
    else
      render :text => "Erreur dans les paramètres de la fonction, voir le code"
    end
  end
  
  # Méthode pour créer des paires de comboBox en fonction d'une définition
  # params[:def] contient la définition actuelle du mapping de la collection
  # params[:tags] contient les tags trouvés dans les résultats
  # Retour : Les comboBox préselectionnées sur la définition du mapping
  #
  def creationDef
    if ((params[:tags] != nil) && (params[:def] != nil))
      definition = params[:def]  # On récupère la définition présente
      tags = params[:tags]  # On récupère les tags
      def_split=definition.split(";")
      tags_split=tags.split(";")
      res=""
      k=0
      id=0
      def_split.length.times do  # Le nombre de fois qu'il y a de champs définis
        i=0
        selection=0
        def_split_k=def_split[k].split('=')  # On sépare la définition
        menus="<option value=\"Vide\"></option>"
        tags_split.length.times do
          if ((tags_split[i]==def_split_k[1]) && (selection==0)) # Si c'est le champ de la définition
            menus+= "<option SELECTED value=\"#{tags_split[i]}\">#{tags_split[i]}</option>"  # On indique que c'est celui ci qui doit être sélectionné
            selection=1
          else
            menus+= "<option value=\"#{tags_split[i]}\">#{tags_split[i]}</option>"
          end
          i+=1
        end
        if (selection != 0)  # Si on a sélectionné quelque chose, ça veut dire que la comboBox sert à quelque chose
          selection=0
          comboRecord=getComboRecord(id)
          comboRecord.each { |element|
            if ((element.include?(def_split_k[0])) && (selection==0))  # Si c'est cet élément qui est dans la définition
              element.sub!("value","SELECTED value")  # On indique que c'est celui ci qui doit être sélectionné
              selection=1
            end
          }
          if (selection != 0)
            res+=comboRecord.join + "<select id=\"combo_#{id.to_s}\" onchange=\"comboChange()\">" + menus + "</select>" + "<br><br>"  # On ajoute le menu formé à ceux qu'on avait déjà
            id+=1
          end
          k+=1
        end
      end
      if (res != "")  # Si on a formé au moins un couple
        res += "hidden #{id}"
        render :text => res  # On le renvoie
      else  # Sinon, on en forme un vierge
        i = 0
        menus="<option value=\"Vide\"></option>"
        tags_split.length.times do
          menus+= "<option value=\"#{tags_split[i]}\">#{tags_split[i]}</option>"  # On forme les balises avec ces tags
        i+=1
        end
        res+=getComboRecord(0).join + "<select id=\"combo_0\" onchange=\"comboChange()\">" + menus + "</select>" + "<br><br>"
        # On forme les comboBox
        render :text => res  # On renvoie le résultat
      end
    else
      render :text => "Erreur dans les paramètres de la fonction, voir le code"
    end
  end
  
  # Méthode pour créer la comboBox pour les champs record avec l'identifiant passé en argument
  # id contient l'identifiant désiré pour la comboBox
  # Retour : un tableau contenant toutes les options de la comboBox
  #
  def getComboRecord(id)
  res = ["<select id=\"record_#{id.to_s}\" onchange=\"comboChange()\">",
    "<option value=\"Vide\"></option>",
    "<option value=\"ptitle\">ptitle</option>",
    "<option value=\"title\">title</option>",
    "<option value=\"atitle\">atitle</option>",
    "<option value=\"isbn\">isbn</option>",
    "<option value=\"issn\">issn</option>",
    "<option value=\"abstract\">abstract</option>",
    "<option value=\"date\">date</option>",
    "<option value=\"author\">author</option>",
    "<option value=\"link\">link</option>",
    "<option value=\"id\">id</option>",
    "<option value=\"source\">source</option>",
    "<option value=\"doi\">doi</option>",
    "<option value=\"openurl\">openurl</option>",
    "<option value=\"direct_url\">direct_url</option>",
    "<option value=\"thumbnail_url\">thumbnail_url</option>",
    "<option value=\"static_url\">static_url</option>",
    "<option value=\"subject\">subject</option>",
    "<option value=\"publisher\">publisher</option>",
    "<option value=\"relation\">relation</option>",
    "<option value=\"contributor\">contributor</option>",
    "<option value=\"coverage\">coverage</option>",
    "<option value=\"rights\">rights</option>",
    "<option value=\"callnum\">callnum</option>",
    "<option value=\"material_type\">material_type</option>",
    "<option value=\"format\">format</option>",
    "<option value=\"vendor_name\">vendor_name</option>",
    "<option value=\"vendor_url\">vendor_url</option>",
    "<option value=\"volume\">volume</option>",
    "<option value=\"issue\">issue</option>",
    "<option value=\"number\">number</option>",
    "<option value=\"page\">page</option>",
    "<option value=\"holdings\">holdings</option>",
    "<option value=\"raw_citation\">raw_citation</option>",
    "<option value=\"oclc_num\">oclc_num</option>",
    "<option value=\"theme\">theme</option>",
    "<option value=\"category\">category</option>",
    "<option value=\"lang\">lang</option>",
    "<option value=\"identifier\">identifier</option>",
    "<option value=\"availability\">availability</option>",
    "</select>"]
    return res
  end
  
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = SearchTabFilter.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = SearchTab.load_groups;
    @primaryDocumentTypes = PrimaryDocumentType.find(:all)
  end
  
  def index
    list
    render :action => 'list'
  end
  
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  
  # Build a filter corresponding to the parameters passed in params
  # Apply the conditions to the result set
  def list
    conditions = Array.new
    # Filter on the tabs which this collection can be searched from
    conditions.push("(id IN (SELECT c.id 
                   FROM collection_groups cg, collection_group_members cgm 
                   INNER JOIN collections c 
                   ON (cgm.collection_id = c.id) 
                   WHERE (cgm.collection_group_id = cg.id) 
                   AND (cg.tab_id = #{params[:tab_id_filter][0]})))") unless params[:tab_id_filter].nil? or params[:tab_id_filter][0].blank?
    # Filter on the name of the collection               
    conditions.push("(name LIKE '#{params[:collection][:name]}')") unless params[:collection].nil? or params[:collection][:name].blank?
    conditions.push("(alt_name LIKE '#{params[:collection][:alt_name]}')") unless params[:collection].nil? or params[:collection][:alt_name].blank?
    conditions.push("(conn_type LIKE '#{params[:collection][:conn_type]}')") unless params[:collection].nil? or params[:collection][:conn_type].blank?
    where_cond = conditions.join(" AND ").gsub(/\*/,"%").chomp(" AND ")
    
    @collection_pages, @collections = paginate :collections, :per_page => 20, 
      :order => 'alt_name asc', :conditions=> where_cond
    @display_columns = ['alt_name', 'name']
  end
  
  def show
    @collection = Collection.find(params[:id])
  end
  
  def new
    @collection = Collection.new
  end
  
  def create
    @collection = Collection.new(params[:collection])
    if @collection.save
      flash[:notice] = translate('COLLECTION_CREATED')
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @collection = Collection.find(params[:id])
  end
  
  def test
    @collection = Collection.find(params[:id])
  end
  
  def update
    @collection = Collection.find(params[:id])
    if @collection.update_attributes(params[:collection])
      flash[:notice] = translate('COLLECTION_UPDATED')
      redirect_to :action => 'show', :id => @collection
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    Collection.find(params[:id]).destroy
    if params[:id] != ''
      CollectionGroupMember.delete_all( "collection_id=" + params[:id].dump)
      HarvestSchedule.delete_all( "collection_id=" + params[:id].dump)
    end
    redirect_to :action => 'list'
  end
end
