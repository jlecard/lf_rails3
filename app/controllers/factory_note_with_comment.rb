class FactoryNoteWithComments < ActiveRecord::Base
  
  def self.createNoteWithComments(note, comments)
    
    if note.nil?
      return nil
    end
    
    n = Struct::NoteWithComments.new()
    n.note = note;
    n.comments_count = comments.size;
    n.comments = comments;
    return n
  end
  
end