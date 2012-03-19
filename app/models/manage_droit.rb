
require 'rubygems'
require 'composite_primary_keys'

class ManageDroit < ActiveRecord::Base
  
  set_primary_keys :id_perm, :id_role, :id_collection, :id_lieu
  belongs_to :manage_role, :foreign_key => :id_role
  
  def findInObject(searchObject, conditions)
    if ((searchObject.blank?()) || (conditions.blank?()))
      return ;
    end
    
    resultat  = Array.new();
    len       = conditions.length();
    
    searchObject.each do |search_object|
      flag = len;
      conditions.each do |key, value|
        if ((!search_object[key].blank?) && (search_object[key] == value))
          flag -= 1;
        end
      end
      if (flag == 0)
        resultat = search_object;
      end
    end
    return (resultat);
  end
  
  def self.GetCollectionsAndPermissions(infos_user)
    begin
      id_lieu = ManageRole.GetIdLieu(infos_user);
      
      id_roles_lf = ManageRole.GetIdRoles(infos_user)
      
      id_roles = id_roles_lf.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      
      collections_permissions = ManageDroit.find_by_sql("SELECT id_perm,id_collection FROM manage_droits WHERE id_lieu =  '#{id_lieu}' AND id_role IN #{id_roles} ")        
    rescue => err
      logger.error("[ManageDroit] [GetCollectionsAndPermissions] #{err.message}")
    end
    logger.info("[ManageDroit] [GetCollectionsAndPermissions] infos_user : #{infos_user} [roles: #{id_roles_lf}, lien: #{id_lieu}]=> #{collections_permissions}")
    return collections_permissions
  end
  
  def self.GetDroits(infos_user,coll_id)
    droits = []
    begin
      id_lieu = ManageRole.GetIdLieu(infos_user)
      
      roles_lf_id = ManageRole.GetIdRoles(infos_user)
      
      roles = roles_lf_id.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      
      droits = ManageDroit.find(:all, :conditions => " id_lieu = '#{id_lieu}' and id_collection = #{coll_id} and id_role IN #{roles} ")
      if !droits.nil? and !droits.empty? 
        return ManageDroit.filterDroits(droits)
      else
        return nil
      end
    rescue => err
      logger.error("[ManageDroit] [GetDroits] #{err.message}")
    end
    logger.debug("[ManageDroit] [GetDroits] infos_user : #{infos_user} [roles: #{roles_lf_id}, lien: #{id_lieu}]=> #{droits}")
    
    return ManageDroit.new
  end
  
  def self.filterDroits(droits)
    begin
      if droits.nil?
        return nil
      end
      logger.debug("[ManageDroit][filterDroits] droits : #{droits.inspect}")
      
      droit_filtered = nil
      
      droits.each do |drt|
        if(drt.id_perm == ACCESS_ALLOWED)
          logger.debug("[ManageDroit][filterDroits] droits : PERM : #{drt.id_perm}  +  LIEU : #{drt.id_lieu}  +  ROLE : #{drt.id_role}  +  COLLECTION : #{drt.id_collection}")
          return drt
        else
          droit_filtered = drt
        end
      end
    rescue => err
      logger.error("[ManageDroit][filterDroits] #{err.message}")
      logger.error("[ManageDroit][filterDroits] #{err.backtrace.join("\n")}")
    end
    
    if !droit_filtered.nil?
      logger.debug("[ManageDroit][filterDroits] droits : PERM : #{droit_filtered.id_perm}  +  LIEU : #{droit_filtered.id_lieu}  +  ROLE : #{droit_filtered.id_role}  +  COLLECTION : #{droit_filtered.id_collection}")
    end
    return droit_filtered
  end
  
end
