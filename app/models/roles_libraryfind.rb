

class RolesLibraryfind
    attr_accessor :yroles;

    @yroles = YAML::load_file(RAILS_ROOT + "/config/roles_libraryfind.yml");

    def self.loadRole(roleName)
        return (@yroles[roleName]);
    end

    def self.findAll()
        return (@yroles);
    end
end