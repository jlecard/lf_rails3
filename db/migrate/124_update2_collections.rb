class Update2Collections < ActiveRecord::Migration

  def self.up
    add_column(:collections, :has_right, :boolean, :default => 0)
    add_column(:collections, :class_handle_right, :text)
  end
  
  def self.down
    remove_column :collections, :has_right
    remove_column :collections, :class_handle_right
  end

end