  # Atos Origin France - 
  # Tour Manhattan - La Défense (92)
  # roger.essoh@atosorigin.com
  
  
  class Comment < ActiveRecord::Base
    
    belongs_to :community_users, :foreign_key => :uuid
    belongs_to :note, :foreign_key => :note_id, :dependent => :destroy
    
    has_many :comments_alerts, :foreign_key => :comment_id, :dependent => :destroy
    has_one   :objects_count, :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_COMMENT} "
    has_many :comment_user_evaluations, :foreign_key => :comment_id, :dependent => :destroy    
    
    
    after_create { |comment|
      begin
        if(!comment.nil?)
          logger.debug("[Comment] after_create comment : #{comment.id} ")
          # Increment statistics only if workflow_validation = 0 <==> comment.workflow = 1
          if(comment.workflow == 1)
            if(comment.parent_id.nil? or comment.parent_id == 0)
              # increment comment count for user
              ObjectsCount.incrementObjectsCount(ENUM_COMMUNITY_USER, comment.uuid, ENUM_COMMENT, 1, comment.state)
            
              # increment comment count for object
              ObjectsCount.incrementObjectsCount(comment.object_type, comment.object_uid, ENUM_COMMENT, 1, comment.state)
            end
            
            if !comment.parent_id.nil? and comment.parent_id != 0
              # increment comment count for parent comment
              ObjectsCount.incrementObjectsCount(ENUM_COMMENT, comment.parent_id, ENUM_COMMENT, 1, COMMENT_PUBLIC) 
            else
              # create count for comment if not a child
              ObjectsCount.createCount(ENUM_COMMENT, comment.id)
            end
            
            log_management = LogManagement.new()
            log_management.addLogComment(comment.object_uid, comment.object_type, 1)
            
          end
        end
      rescue => e
        logger.error("[Comment][after_create] Error : " + e.message)
        raise e
      end
    }
    
    after_destroy { |comment|
      begin
        if(!comment.nil?)
          logger.debug("[Comment] after_destroy comment : #{comment.id} ")        
          # Decrement statistics only if workflow_validation = 0 <==> comment.workflow = 1
          if(comment.workflow == 1)
            if(comment.parent_id.nil? or comment.parent_id == 0)
              # decrement comment count for user
              ObjectsCount.decrementObjectsCount(ENUM_COMMUNITY_USER, comment.uuid, ENUM_COMMENT, 1, comment.state)
              # decrement comment count for object
              ObjectsCount.decrementObjectsCount(comment.object_type, comment.object_uid, ENUM_COMMENT, 1, comment.state)
            end
            if(comment.state == COMMENT_PUBLIC)
              if !comment.parent_id.nil? and comment.parent_id != 0
                # decrement comment count for parent comment
                obj = ObjectsCount.getObjectCountById(ENUM_COMMENT, comment.parent_id)
                if(!obj.nil?)
                  ObjectsCount.decrementObjectsCount(ENUM_COMMENT, comment.parent_id, ENUM_COMMENT, 1, COMMENT_PUBLIC)
                end
              end
              # Delete comment's children
              Comment.destroy_all(" parent_id = #{comment.id} ")
            end
            
            log_management = LogManagement.new()
            log_management.addLogComment(comment.object_uid, comment.object_type, 0)
          end
        end
      rescue => e
        logger.error("[Comment][after_destroy] Error after destroy comment (id = #{comment.id}) : " + e.message )
        raise e
      end
    }
    
    
    # Method addComment
    def self.addComment(content,uuid,object_type,object_uid,title,parent_id,state,note_id=0)
      comment = Comment.new;
      comment.comment_date = Time.new;
      comment.content = content;
      comment.uuid = uuid;
      comment.workflow = COMMENT_VALIDATED;
      comment.workflow_date = Time.new;
      comment.object_type = object_type;
      comment.object_uid = object_uid;
      comment.title = title;
      comment.parent_id = parent_id;
      comment.state = state;
      comment.note_id = note_id
      comment.save;
      return comment;
    end
    
    
    
    # Method getCommentById
    def self.getCommentById(comment_id)
      return Comment.find(:first, :conditions => " id=#{comment_id} ");
    end
    
    
    # Method validateComment
    def self.validateComment(comments_id,workflow_manager)
      comments_id.each do |comment_id|
        com = Comment.find(comment_id)
        if(!com.nil? and com.workflow != COMMENT_VALIDATED)
          # increment comment count for user
          ObjectsCount.incrementObjectsCount(ENUM_COMMUNITY_USER, com.uuid, ENUM_COMMENT, 1)
          
          # increment comment count for object
          ObjectsCount.incrementObjectsCount(com.object_type, com.object_uid, ENUM_COMMENT,1,com.state)
          
          if(com.state == COMMENT_PUBLIC)
            # create count for comment
            ObjectsCount.createCount(ENUM_COMMENT, com.id) 
            if !com.parent_id.nil?
              # increment comment count for parent comment
              ObjectsCount.incrementObjectsCount(ENUM_COMMENT, com.parent_id, ENUM_COMMENT, 1) 
            end
          end
        end
      end
      Comment.update_all( {:workflow => COMMENT_VALIDATED, :workflow_manager => "#{workflow_manager}", :workflow_date => Time.new}, {:id => comments_id} );
    end
    
    def self.unvalidateComment(comment_id)
      com = Comment.find(comment_id)
      if (!com.nil?)
        Comment.update_all( {:workflow => COMMENT_NOT_VALIDATED, :workflow_date => Time.new}, {:id => "#{comment_id}"} );
      end
    end
    
    # Method deleteComment
    def self.deleteComment(comments_id) 
      Comment.destroy(comments_id);
    end
    
    def self.deleteAllUserComment(uuid)
      Comment.destroy_all("uuid = '#{uuid}'")
    end
    
    
    # Method changeCommentState
    def self.changeCommentState(comment, new_state)
      comment.state = new_state
      comment.save
      return comment
    end
    
    
    # Method getCommentsByNote
    def self.getCommentsByNote(object_uid, note)
      return Comment.find_by_sql("SELECT comments.id from comments, notes WHERE comments.object_uid = '#{object_uid}' AND comments.note_id = notes.id AND notes.note = #{note}")
    end
    
    
    # Method : getCommentByUserAndObject
    def self.getCommentByUserAndObject(object_type, object_uid, uuid)
      return Comment.find(:first, :conditions => " uuid = '#{uuid}' and object_type = #{object_type} and object_uid = '#{object_uid}'" );
    end
    
    
    # Method getMostPertinentComment
    def self.getMostPertinentComment(object_uid)
      
      conditions = "object_uid = '#{object_uid}'" 
      
      comments = Comment.find(:all, :conditions => " #{conditions}", :order => "comment_relevance DESC");
      comments_structs = []
      if(!comments.empty?)
        comments.each do |com|
          comments_children_structs = []
          comment_children = Comment.getCommentsChildren(com.id)
          cm_object_type = com.object_type
          cm_object_uid = com.object_uid
          if (cm_object_type == ENUM_NOTICE)
            cm_object_uid, idColl, idSearch = UtilFormat.parseIdDoc(cm_object_uid)
            object_title = Notice.find(:first, :conditions => " doc_identifier = '#{cm_object_uid}'").dc_title
          elsif (cm_object_type == ENUM_LIST)
            object_title = List.find(:first, :conditions => " id = '#{cm_object_uid}'").title
          end
          comment_children.each do |cc|
            comments_children_structs << FactoryComment.createComment(cc, [], object_title)
          end
          if (!cm_object_uid.nil? and !cm_object_type.nil? and (cm_object_type == ENUM_NOTICE or cm_object_type == ENUM_LIST))
            comments_structs << FactoryComment.createComment(com,comments_children_structs, object_title)
          else
            comments_structs << FactoryComment.createComment(com,comments_children_structs)
          end
          
        end
      end
      
      return comments_structs
    end
    
    
    # Method getCommentsByUser
    def self.getCommentsByUserAndObject(object_type,object_uid,uuid,limit,offset,sort,direction,workflow)
      conditions = " comments.uuid = '#{uuid}' and comments.object_type=#{object_type} and comments.parent_id is NULL ";
      if SORT_DATE == sort
        c_sort = "comments.comment_date"
      end
      
      if DIRECTION_UP == direction
        c_direction = "ASC"
      elsif DIRECTION_DOWN == direction
        c_direction = "DESC"
      end
      
      if(workflow != nil)
        conditions = conditions," and workflow=#{workflow} ";
      end
      if(object_uid != nil)
        conditions = conditions," and comments.object_uid='#{object_uid}' ";
      end
      comments_users = []
      comments = Comment.find(:all, :conditions => "#{conditions}", :order => "#{c_sort} #{c_direction}", :offset => offset.to_i, :limit => limit.to_i);
      if(!comments.empty?)
        comments.each do |com|
          comment_children = Comment.getCommentsChildren(com.id)
          comments_users << FactoryComment.createComment(com,comment_children)
        end
      end
      
      return comments_users
    end
    
    
    # Method getCommentsByObject
    def self.getCommentsByObject(object_type,object_uid,limit=DEFAULT_MAX_COMMENT,offset=0,sort=SORT_DATE,direction=DIRECTION_DOWN,workflow=COMMENT_VALIDATED)
      
      if SORT_DATE == sort
        c_sort = "comments.comment_date"
      end
      
      if DIRECTION_UP == direction
        c_direction = "ASC"
      elsif DIRECTION_DOWN == direction
        c_direction = "DESC"
      end
      
      conditions = " comments.object_type=#{object_type} and comments.object_uid='#{object_uid}' and state = #{COMMENT_PUBLIC} AND parent_id is NULL ";
      
      if(workflow != nil)
        conditions = conditions," and comments.workflow = #{workflow}";
      end
      #comments = Comment.find(:all, :conditions => "#{conditions}", :order => "#{c_sort} #{c_direction}", :offset => offset.to_i, :limit => limit.to_i, :include => [community_users,note]);
      comments = Comment.find(:all, :conditions => "#{conditions}", :order => "#{c_sort} #{c_direction}", :offset => offset.to_i, :limit => limit.to_i);
      
      return comments
    end
    
    
    # Method getCommentsChildren
    def self.getCommentsChildren(comment_id)
      return Comment.find(:all, :conditions => " parent_id = #{comment_id} ")
    end
    
    
    # Method getCommentsByUser
    def self.getCommentsByUser(uuid,owner,limit,offset,sort,direction)
      if SORT_DATE == sort
        c_sort = "comments.comment_date"
      elsif SORT_PERTINENCE == sort
        c_sort = "comments.comment_relevance"
      end
      if DIRECTION_UP == direction
        c_direction = "ASC"
      elsif DIRECTION_DOWN == direction
        c_direction = "DESC"
      end
      if(offset.nil?)
        offset = 1
      end
      if(limit.nil?)
        limit = 10
      end
      
      conditions = " uuid = '#{uuid}' and workflow = #{COMMENT_VALIDATED} "
      if(!owner)
        conditions += " and state = #{COMMENT_PUBLIC}"
      end 
      comments = Comment.find(:all, :conditions => "#{conditions}", :order => "#{c_sort} #{c_direction}", :offset => offset.to_i, :limit => limit.to_i);
      return comments      
    end
    
    
    # Method getCommentsByObjectAndNote
    def self.getCommentsByObjectAndNote(object_type,object_uid,note, limit, offset,sort,direction, workflow = COMMENT_VALIDATED)
      
      if SORT_DATE == sort
        c_sort = "comments.comment_date"
      end
      
      if DIRECTION_UP == direction
        c_direction = "ASC"
      elsif DIRECTION_DOWN == direction
        c_direction = "DESC"
      end
      
      notes = Note.find(:all, :conditions => " note = #{note} ")
      notes_ids = []
      notes.each do |nt|
        notes_ids << nt.id
      end
      notes_ids = notes_ids.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      conditions = " comments.workflow=#{workflow} and comments.object_type=#{object_type} and comments.object_uid='#{object_uid}' and note_id IN #{notes_ids} and state = #{COMMENT_PUBLIC} ";
      comments = Comment.find(:all, :conditions => " #{conditions}", :order => "#{c_sort} #{c_direction}", :offset => offset.to_i, :limit => limit.to_i);
      
      comments_notes = []
      if(!comments.empty?)
        comments.each do |com|
          comment_children = Comment.getCommentsChildren(com.id)
          comments_notes << FactoryComment.createComment(com,comment_children)
        end
      end
      return comments_notes
      
    end
    
    #retourne le nb de commentaire privee d'un utilisateur sur un objet
    def self.getUserPrivateCommentsCount(object_uid, object_type, uuid)
      priv_count = 0
      if (!object_uid.nil? and !uuid.nil?)
        priv_count = Comment.count(:conditions => "object_uid = '#{object_uid}' and object_type = '#{object_type}' and state = 0 and uuid = '#{uuid}' AND parent_id is null")
      end
      return priv_count
    end
    
    def self.getCountCommentsByUserType(object_uid, object_type, uuid)
      return Comment.find_by_sql ["select DISTINCT(user_type), COUNT(id) as 'count' FROM comments, community_users WHERE comments.object_uid = '#{object_uid}' AND comments.object_type = #{object_type} AND (state = 1 OR (state = 0 AND comments.uuid = '#{uuid}')) AND comments.uuid = community_users.uuid AND parent_id is null GROUP BY user_type"]
    end
    
    # Method getCommentsByObjectAndUserType
    def self.getCommentsByObjectAndUserType(object_type,object_uid,user_type,limit,offset,sort,direction)
      
      if SORT_DATE == sort
        c_sort = "comments.comment_date"
      end
      
      if DIRECTION_UP == direction
        c_direction = "ASC"
      elsif DIRECTION_DOWN == direction
        c_direction = "DESC"
      end
      
      users = CommunityUsers.find(:all, :conditions => " user_type = '#{user_type}' ")
      users_ids = []
      users.each do |u|
        users_ids << u.uuid
      end
      users_ids = users_ids.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      conditions = " comments.object_type=#{object_type} and comments.object_uid='#{object_uid}' and uuid IN #{users_ids} and state = #{COMMENT_PUBLIC} ";
      comments = Comment.find(:all, :conditions => " #{conditions}", :order => "#{c_sort} #{c_direction}", :offset => offset.to_i, :limit => limit.to_i);
      
      comments_user_types = []
      if(!comments.empty?)
        comments.each do |com|
          comment_children = Comment.getCommentsChildren(com.id)
          comments_user_types << FactoryComment.createComment(com,comment_children)
        end
      end
      return comments_user_types
      
    end
    
    def self.getCommentsAlerts()
      comments = Comment.find_by_sql("SELECT comments.* FROM comments, comments_alerts WHERE id = comment_id GROUP BY comment_id");
      comments_structs = []
      if(!comments.empty?)
        comments.each do |com|
          comments_children_structs = []
          cm_object_type = com.object_type
          cm_object_uid = com.object_uid
          if (cm_object_type == ENUM_NOTICE)
            cm_object_uid, idColl, idSearch = UtilFormat.parseIdDoc(cm_object_uid)
            object_title = Notice.find(:first, :conditions => " doc_identifier = '#{cm_object_uid}'").dc_title
          elsif (cm_object_type == ENUM_LIST)
            object_title = List.find(:first, :conditions => " id = '#{cm_object_uid}'").title
          end
          if (!cm_object_uid.nil? and !cm_object_type.nil? and (cm_object_type == ENUM_NOTICE or cm_object_type == ENUM_LIST))
            comments_structs << FactoryComment.createComment(com,comments_children_structs, object_title)
          else
            comments_structs << FactoryComment.createComment(com,comments_children_structs)
          end
        end
      end 
      return comments_structs
    end
    
     def self.getOneComment(object_uid, workflow)
      
      conditions = " MD5(id) = '#{object_uid}' AND state = 1 and workflow = 1"
      
      comments = Comment.find(:all, :conditions => " #{conditions}");
      comments_structs = []
      if(!comments.empty?)
        comments.each do |com|
          comments_children_structs = []
          cm_object_type = com.object_type
          cm_object_uid = com.object_uid
          if (cm_object_type == ENUM_NOTICE)
            cm_object_uid, idColl, idSearch = UtilFormat.parseIdDoc(cm_object_uid)
            object_title = Notice.find(:first, :conditions => " doc_identifier = '#{cm_object_uid}'").dc_title
          elsif (cm_object_type == ENUM_LIST)
            object_title = List.find(:first, :conditions => " id = '#{cm_object_uid}'").title
          end
          comment_children = Comment.getCommentsChildren(com.id)
          comment_children.each do |cc|
            comments_children_structs << FactoryComment.createComment(cc, [], object_title, nil)
          end
          get_retour = FactoryComment.createComment(com,comments_children_structs, object_title)
          if (!get_retour.nil?)
            comments_structs << get_retour
          end
        end
      end
      
      return comments_structs
    end
    
    def self.updateAllUserCommentsState(uuid, state)
      Comment.update_all("state = #{state}", "uuid = '#{uuid}'")
    end
    
    def self.getComments(object_type, object_uid, uuid, note, user_type, state, workflow=COMMENT_VALIDATED, limit=DEFAULT_MAX_COMMENT, offset=0, sort=SORT_DATE, direction=DIRECTION_DOWN)
      
      if SORT_DATE == sort
        c_sort = "comments.comment_date"
      else 
        if SORT_RELEVANCE == sort
          c_sort = "comments.comment_relevance"
        end
      end
      
      if DIRECTION_UP == direction
        c_direction = "ASC"
      elsif DIRECTION_DOWN == direction
        c_direction = "DESC"
      end
      
      conditions = " comments.parent_id is NULL and comments.workflow = #{workflow} "
      if(!object_type.nil? and !object_uid.nil?)
        conditions += " and comments.object_type = #{object_type} and comments.object_uid = '#{object_uid}' "
      end
      
      
      if(!note.nil?)
        notes = Note.find(:all, :conditions => " note = #{note} ")
        notes_ids = []
        notes.each do |nt|
          notes_ids << nt.id
        end
        #if !notes_ids.empty?
        notes_ids = notes_ids.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
        conditions += " and note_id IN #{notes_ids} "
        #end
      end
      if (object_type == ENUM_COMMUNITY_USER)
        fin = ""
        if (!state.nil?)
          conditions += " and (state = #{state}"
          fin =")"
        end 
        conditions += " and uuid = '#{uuid}'#{fin} "
      elsif (!state.nil?)
        conditions += " and (state = #{state} or uuid = '#{uuid}') "
      else
        conditions += " and uuid = '#{uuid}' "
      end
      comments = Comment.find(:all, :conditions => " #{conditions}", :order => "#{c_sort} #{c_direction}", :offset => offset.to_i, :limit => limit.to_i);
      comments_structs = []
      if(!comments.empty?)
        comments.each do |com|
          comments_children_structs = []
          comment_children = Comment.getCommentsChildren(com.id)
          cm_object_type = com.object_type
          cm_object_uid = com.object_uid
          if (cm_object_type == ENUM_NOTICE)
            cm_object_uid, idColl, idSearch = UtilFormat.parseIdDoc(cm_object_uid)
            object_title = Notice.find(:first, :conditions => " doc_identifier = '#{cm_object_uid}'").dc_title
          elsif (cm_object_type == ENUM_LIST)
            object_title = List.find(:first, :conditions => " id = '#{cm_object_uid}'").title
          end
          comment_children.each do |cc|
            comments_children_structs << FactoryComment.createComment(cc, [], object_title, nil)
          end
          if (!cm_object_uid.nil? and !cm_object_type.nil? and (cm_object_type == ENUM_NOTICE or cm_object_type == ENUM_LIST))
            get_retour = FactoryComment.createComment(com,comments_children_structs, object_title, user_type)
            if (!get_retour.nil?)
              comments_structs << get_retour
            end
          else
            get_retour = FactoryComment.createComment(com,comments_children_structs, nil, user_type)
            if (!get_retour.nil?)
              comments_structs << get_retour
            end
          end
        end
      end
      
      return comments_structs
      
    end
    
  end
