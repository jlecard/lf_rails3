
class CreateManageRoles < ActiveRecord::Migration
    def self.up
        create_table (:manage_roles, :primary_key => [:id_role]) do |t|
            t.column :id_role,  :string
        end
    end

    def self.down
        drop_table :manage_roles;
    end
end
