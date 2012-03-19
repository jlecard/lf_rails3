class UpdateLogConsultAddProperties < ActiveRecord::Migration
  def self.up
    add_column :log_consults, :profil, :string
    add_column :log_consults, :action, :string
    add_column :log_consults, :date, :string
    add_column :log_consults, :vendor_name, :string
    add_column :log_consults, :context, :string
    add_column :log_consults, :material_type, :string
    add_column :log_consults, :theme, :string
    remove_column :log_consults, :nb_consult
    add_column :log_consults, :created_at, :datetime
    add_column :log_consults, :updated_at, :datetime
  end
  
  def self.down
    remove_column :log_consults, :profil
    remove_column :log_consults, :action
    remove_column :log_consults, :date
    remove_column :log_consults, :vendor_name
    remove_column :log_consults, :context
    remove_column :log_consults, :material_type
    remove_column :log_consults, :theme
    add_column :log_consults, :nb_consult, :integer
    remove_column :log_consults, :created_at
    remove_column :log_consults, :updated_at
  end
end