class CreateThemes < ActiveRecord::Migration
  def self.up
    create_table :themes do |t|
      t.column :reference, :string, :limit => 10, :null => false
      t.column :label, :string, :null => false
      t.column :sort, :int, :default => 0
      t.column :level, :int, :default => 1
      t.column :parent, :string, :limit => 10
    end
    
    add_index :themes, :reference, :unique => true
    
    create_table :themes_references do |t|
      t.column :ref_theme,  :string, :limit => 10, :null => false
      t.column :ref_source, :string, :null => false
      t.column :source, :string, :null => false
    end
    
    add_index :themes_references, :ref_theme
    add_index :themes_references, :ref_source
    
  end

  def self.down
    remove_index :themes_references, :ref_theme
    remove_index :themes_references, :ref_source
    remove_index :themes, :reference
    drop_table :themes_references
    drop_table :themes
  end
end