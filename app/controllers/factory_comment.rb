class FactoryComment
  
  def self.createComment(comment, comment_children = [], object_title=nil, user_type=nil)
    
    
    if comment.nil?
      return nil;
    end
    
    com = Struct::CommentStruct.new();
    
    com.id = comment.id;
    com.comment_date = comment.comment_date;
    com.content = comment.content;
    com.comment_relevance = comment.comment_relevance;
    com.like_count = comment.like_count;
    com.dont_like_count = comment.dont_like_count;
    com.title = comment.title;
    com.state = comment.state;    
    com.parent_id = comment.parent_id;
    com.object_uid = comment.object_uid
    com.object_type = comment.object_type
    com.object_title = object_title
    
    user = comment.community_users;
    if(!user.nil?)
      com.user_name = user.name;
      com.user_type = user.user_type;
      com.uuid = user.uuid;
    else
      raise("No user !!")
    end
    
    if (comment.comments_alerts)
      alert = comment.comments_alerts;
      if (!alert.nil?)
        com.alert = alert;
      end
    end
    
    note = comment.note
    if(!note.nil?)
      com.note = note.note;
    end
    
    com.comment_children = comment_children;
    if (user_type.nil?)
      return com;
    else 
      if(user_type == com.user_type)
        return com;
      else
        return nil
      end
    end
  end
end