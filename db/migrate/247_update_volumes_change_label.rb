class UpdateVolumesChangeLabel < ActiveRecord::Migration
  
  def self.up
	  change_column :volumes, :label, :text
	  change_column :volumes, :launch_url, :text
	  change_column :volumes, :location, :text
	  change_column :volumes, :link, :text
	  change_column :volumes, :link_label, :text
  end
  
  def self.down
	     
  end
  
end