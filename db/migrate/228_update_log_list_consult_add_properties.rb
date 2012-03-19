class UpdateLogListConsultAddProperties < ActiveRecord::Migration
  def self.up
    add_column :log_list_consults, :profil, :string
    add_column :log_list_consults, :create_delete, :integer
    remove_column :log_list_consults, :nb_consult
  end
  
  def self.down
    remove_column :log_list_consults, :profil
    remove_column :log_list_consults, :create_delete
    add_column :log_list_consults, :nb_consult, :integer
  end
end