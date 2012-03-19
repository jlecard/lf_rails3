
class ManageRole < ActiveRecord::Base
  
  set_primary_key "id_role"
  has_many :manage_droit, :foreign_key => :id_role, :dependent => :destroy
  
  def self.GetIdRoles(infos_user)
    begin
      roles_lf = RolesLibraryfind.findAll()
      roles = Array.new
      
      if(roles_lf.nil? and !roles_lf.empty?)
        roles << ""
        return roles
      end
      logger.debug("[ManageRole][GetIdRoles] #{roles_lf.size} libraryfind roles found")
      logger.debug("[ManageRole][GetIdRoles] roles LF: #{roles_lf.inspect} => try to match with : #{infos_user.inspect}")
      
      if(infos_user.state_user=="False")
        roles << ANONYM_ROLE     # Anonym role
        logger.debug("[ManageRole][GetIdRoles] role found : #{ANONYM_ROLE}")
      else
        groupesUser = infos_user.group_user
        rolesUser = infos_user.role_user
        
        roles_lf.each do |roleLF|
          
          properties = roleLF[1]
          isGroupMatch = false
          isRolesMatch = false
          
          # ignoreAnonyme role
          if properties['Id'] != ANONYM_ROLE and properties['Id'] != BASIC_ROLE
            
            if properties['Groups'].blank?
              isGroupMatch = true
            else
              properties['Groups'].split(",").each do |g|
                if groupesUser.include?(g)
                  isGroupMatch = true
                  break;
                end
              end
            end
            
            logger.debug("[ManageRole][GetIdRoles] [GLF: #{properties['Groups'].inspect} => GU : #{groupesUser.inspect} = #{isGroupMatch}")
            
            if properties['Roles'].blank?
              isRolesMatch = true
            else
              properties['Roles'].split(",").each do |g|
                if rolesUser.include?(g)
                  isRolesMatch = true
                  break;
                end
              end
            end
            
            logger.debug("[ManageRole][GetIdRoles] [RLF: #{properties['Roles'].inspect} => RU : #{rolesUser.inspect} = #{isRolesMatch}")
            
            if isRolesMatch and isGroupMatch
              logger.debug("[ManageRole][GetIdRoles] Add Role LF #{properties['Id']} for this user")
              roles << properties['Id']
            end
            
          end
          
        end
        
        if roles.empty?
          logger.debug("[ManageRole][GetIdRoles] Add Role LF #{BASIC_ROLE} by default")
          roles << BASIC_ROLE
        end
        
      end
      
      logger.debug("[ManagerRole][GetIdRoles] roles : #{roles.inspect}")
      
      #      # Anonym role or Basic role
      #      if(infos_user.group_user.empty? and infos_user.role_user.empty?)
      #        logger.info("[ManageRole][GetIdRoles] both infos_user.group_user and infos_user.role_user are empty")
      #        if(infos_user.state_user=="True")
      #          logger.info("[ManageRole][GetIdRoles] role found : #{BASIC_ROLE}")
      #          roles << BASIC_ROLE     # Basic role
      #        else
      #          roles << ANONYM_ROLE     # Anonym role
      #          logger.info("[ManageRole][GetIdRoles] role found : #{ANONYM_ROLE}")
      #        end
      #      elsif(!infos_user.group_user.empty? and infos_user.role_user.empty?)
      #        logger.info("[ManageRole][GetIdRoles] infos_user.role_user is empty")
      #        roles_lf.each do |role|
      #          http_groups = role[1]['Groups'].split(',')
      #          http_groups.each do |grp|
      #            if( infos_user.group_user.include?(grp))
      #              roles << role[1]['Id']
      #              logger.info("[ManageRole][GetIdRoles] role found : #{role[1]['Id']}")
      #            end
      #          end
      #        end
      #      elsif(infos_user.group_user.empty? and !infos_user.role_user.empty?)
      #        logger.info("[ManageRole][GetIdRoles] infos_user.group_user is empty")
      #        roles_lf.each do |role|
      #          http_roles = role[1]['Roles'].split(',')
      #          http_roles.each do |rl|
      #            if( infos_user.role_user.include?(rl))
      #              roles << role[1]['Id']
      #              logger.info("[ManageRole][GetIdRoles] role found : #{role[1]['Id']}")
      #            end
      #          end
      #        end
      #      else
      #        logger.info("[ManageRole][GetIdRoles] infos_user.group_user and infos_user.role_user aren't empty")
      #        roles_lf.each do |role|
      #          http_group_auth = false
      #          http_role_auth = false
      #          http_groups = role[1]['Roles'].split(',')
      #          http_groups.each do |grp|
      #            if( infos_user.role_user.include?(grp))
      #              http_group_auth = true
      #            end
      #          end
      #          http_roles = role[1]['Roles'].split(',')
      #          http_roles.each do |rl|
      #            if( infos_user.role_user.include?(rl))
      #              http_role_auth = true
      #            end
      #          end
      #          if http_group_auth and http_role_auth
      #            roles << role[1]['Id']
      #            logger.info("[ManageRole][GetIdRoles] role found : #{role[1]['Id']}")
      #          end
      #        end
      #      end
      #      logger.info("[ManageRole][GetIdRoles] #{roles.size} LF roles corresponding to user #{infos_user.name_user}/#{infos_user.uuid_user}")
      #      if(roles.size==0)
      #        roles << ""
      #      end
      return roles
    rescue => err
      logger.error("[ManageRole][GetIdRoles] #{err.message}")  
    end
    
  end
  
  def self.GetIdLieu(infos_user)
    begin
      if(!infos_user.nil?)
        pr_postes = ProfilPostes.findAll()
        pr_postes.each do |pposte|
          if(pposte[1]['Value']['profil'] == infos_user.location_user)
            logger.debug("[ManageRole][GetIdLieu] profil #{pposte[1]['Value']['profil']} found to location_user #{infos_user.location_user}")
            logger.debug("[ManageRole][GetIdLieu] inspecting pposte #{pposte.inspect}")
            return pposte[0]
          end
        end
        logger.debug("[ManageRole][GetIdLieu] No postes found for this user!")
      end
    rescue => err
      logger.error("[ManageRole][GetIdLieu] #{err.message}")
    end
    return nil
  end
  
  def self.GetIdProfilPost(infos_user)
    begin
      if(!infos_user.nil?)
        pr_postes = ProfilPostes.findAll()
        pr_postes.each do |pposte|
          if(pposte[1]['Value']['profil'] == infos_user.location_user)
            logger.info("[ManageRole][GetIdLieu] profil #{pposte[1]['Value']['profil']} found to location_user #{infos_user.location_user}")
            return pposte[1]['Value']['profil']
          end
        end
        logger.debug("[ManageRole][GetIdLieu] No postes found for this user!")
      end
    rescue => err
      logger.error("[ManageRole][GetIdLieu] #{err.message}")
    end
    return nil
  end
  
  def self.GetBroadcastGroups(infos_user)
    begin
      if(!infos_user.nil? and !infos_user.location_user.blank?)
        groups = ProfilPostes.broadcast_groups(infos_user.location_user)
        logger.debug("[ManageRole][GetDisplayGroups] Found #{groups} for profile #{infos_user.location_user}")
        return groups
      end
    rescue => err
      logger.error("[ManageRole][GetDisplayGroups] #{err.message}")
    end
    return nil
  end
  
end
