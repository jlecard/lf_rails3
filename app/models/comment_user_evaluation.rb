
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com

class CommentUserEvaluation < ActiveRecord::Base
  
  belongs_to :community_users, :foreign_key => :uuid
  belongs_to :comments, :foreign_key => :comment_id

  # Method addCommentUserEvaluation
  def self.addCommentUserEvaluation(uuid,comment,comment_relevance)
    # new comment user evaluation
    com_user_eval = CommentUserEvaluation.new
    com_user_eval.uuid = uuid
    com_user_eval.comment_id = comment.id
    com_user_eval.comment_relevance = comment_relevance.to_i
    
    # update comment like/don't like count
    if( comment_relevance == LIKE_COMMENT)
      comment.like_count += 1;
    else
      comment.dont_like_count += 1;                 
    end
    # update comment_relevance
    comment.comment_relevance = comment.like_count - comment.dont_like_count
    
    comment.save
    com_user_eval.save
    
    return comment
  end
  
  
  # Method updateCommentUserEvaluation
  def self.updateCommentUserEvaluation(comment, com_user_eval, new_comment_relevance)
    # remove old comment evaluation
    comment.comment_relevance -= com_user_eval.comment_relevance
    # update counts like/don't like
    if(com_user_eval.comment_relevance == LIKE_COMMENT)
      comment.like_count -= 1
    elsif(com_user_eval.comment_relevance == DONT_LIKE_COMMENT)
      comment.dont_like_count -= 1
    end
    
    # set new comment_relevance 
    com_user_eval.comment_relevance = new_comment_relevance.to_i
    # update counts like/don't like
    if( new_comment_relevance == LIKE_COMMENT)
      comment.like_count += 1;
    else
      comment.dont_like_count += 1;                 
    end
    # update comment relevance
    comment.comment_relevance = comment.like_count - comment.dont_like_count
    
    com_user_eval.save
    comment.save
    
    return comment
  end

  
  # Method : getCommentUserEvaluation
  def self.getCommentUserEvaluation(comment_id, uuid)
    return CommentUserEvaluation.find(:first, :conditions => " comment_id = #{comment_id} and uuid = '#{uuid}'" )
  end
  
  
end
