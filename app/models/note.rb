  ###################################################################################################################################
  ##                                                                                                                               ##
  ##                                            Developped by Khalil                                                               ##
  ##                                                                                                                               ##
  ###################################################################################################################################
  
  
  
  # Atos Origin France - 
  # Tour Manhattan - La Défense (92)
  # roger.essoh@atosorigin.com
  
  class Note < ActiveRecord::Base
    
    has_many :comments, :foreign_key => [:note_id]
    
    belongs_to :community_users, :foreign_key => :uuid
    
    after_create { |this_note|
      logger.debug("[Note][after_create] create note id #{this_note.id} ")
      ObjectsCount.updateObjectStatistics(this_note.object_type,this_note.object_uid,this_note.note);
      
      log_management = LogManagement.new()
      log_management.addLogNote(this_note.object_type, this_note.object_uid, this_note.note, 1)
    }
    
    after_destroy{ |this_note|
      logger.debug("[Note][after_destroy] destroy note id #{this_note.id} ")
      # Update average_note for object
      owner = true
      obj = (this_note.object_type == ENUM_NOTICE) ? Notice.getNoticeByDocId(this_note.object_uid) : List.getListById(this_note.object_uid)
      if(!obj.nil?)
        if(obj.notes_count - 1 > 0)
          obj.notes_avg = ((obj.notes_avg * obj.notes_count) - this_note.note) / (obj.notes_count - 1)
          obj.notes_count -= 1
        else
          obj.notes_avg = 0
          obj.notes_count = 0
        end
        obj.save
        
        log_management = LogManagement.new()
        log_management.addLogNote(this_note.object_type, this_note.object_uid, this_note.note, 0)
      end
    }
    
    # Method addNote
    def self.addNote(note,uuid,object_type,object_uid)
      v_note = Note.new;
      v_note.note = note;
      v_note.note_date = Time.new;
      v_note.uuid = uuid;
      v_note.object_type = object_type;
      v_note.object_uid = object_uid;
      v_note.save;
      return v_note;
    end
    
    def self.getNote(note_id)
      return Note.find(:first, :conditions => " note_id = #{note_id} ")
    end
    
    def self.getCountCommentsByNote(object_uid, object_type, uuid)
      return Note.find_by_sql ["select DISTINCT(note), COUNT(note) as 'count' FROM comments, notes WHERE comments.object_uid = '#{object_uid}' AND comments.object_type = #{object_type} AND (state = 1 OR (state = 0 AND comments.uuid = '#{uuid}')) AND comments.note_id = notes.id AND parent_id is null GROUP BY note"]
    end

  end
