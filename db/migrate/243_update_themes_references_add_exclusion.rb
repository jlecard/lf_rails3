class UpdateThemesReferencesAddExclusion < ActiveRecord::Migration
  
  def self.up
    add_column :themes_references, :exclusion, :string
	change_column :themes_references, :ref_theme, :string, :null=>true
  end
  
  def self.down
    remove_column :themes_references, :exclusion
	change_column :themes_references, :ref_theme, :string, :null=>false
  end
  
end