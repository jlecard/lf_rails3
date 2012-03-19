class UpdateLogNoteCommentAddProperties < ActiveRecord::Migration
  def self.up
    add_column :log_notes, :int_add, :integer
    add_column :log_notes, :profil, :string
    
    add_column :log_comments, :int_add, :integer
    add_column :log_comments, :profil, :string
    
  end
  
  def self.down
    remove_column :log_comments, :int_add
    remove_column :log_comments, :profil
    
    remove_column :log_comments, :int_add
    remove_column :log_comments, :profil
  end
end