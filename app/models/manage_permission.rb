

class ManagePermission < ActiveRecord::Base
  
  set_primary_key "id_perm"
  belongs_to :manage_droit
  
  
end
