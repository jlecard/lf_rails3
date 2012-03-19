class CreateManagePermissions < ActiveRecord::Migration
  def self.up
    create_table (:manage_permissions, :primary_key => [:id_perm]) do |t|
      t.column :id_perm, :string, :null => false
    end
    
    begin
      permSearch = ManagePermission.new()
      permSearch.id_perm = "REC"
      permSearch.save!()
      permAccess = ManagePermission.new()
      permAccess.id_perm = "ACC"
      permAccess.save!()
    rescue => e
      print e.message
    end
  end
  
  def self.down
    drop_table :manage_permissions;
  end
end
