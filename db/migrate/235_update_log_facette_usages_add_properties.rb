class UpdateLogFacetteUsagesAddProperties < ActiveRecord::Migration
  def self.up
		rename_column :log_facette_usages, :types, :facette
    add_column :log_facette_usages, :label, :string
    add_column :log_facette_usages, :profil, :string
  end

  def self.down
		remove_column :log_facette_usages, :label
    remove_column :log_facette_usages, :profil
    rename_column :log_facette_usages, :facette, :types
  end
end
