
class ProfilPostes
    attr_accessor :yp

    @yp = YAML::load_file(RAILS_ROOT + "/config/profil_postes.yml")

    def self.loadProfil(profilName)
        return (@yp[profilName])
    end

    def self.findAll()
        return (@yp)
    end
    
    def self.broadcast_groups(profilName)
        return (@yp[profilName]["Value"]["Groups"].split(","))
    end
    
    
end
