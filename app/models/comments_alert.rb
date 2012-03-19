class CommentsAlert < ActiveRecord::Base
  
  set_primary_keys :comment_id, :uuid
  
  belongs_to :community_users, :foreign_key => :uuid
  belongs_to :comments, :foreign_key => :comment_id
  
  
  def self.addCommentsAlert(comment_id, uuid, message)
    ca = CommentsAlert.getCommentsAlert(comment_id, uuid)
    if (ca.nil?)
      ca = CommentsAlert.new
    end
    ca.comment_id = comment_id
    ca.uuid = uuid
    ca.message = message
    ca.send_date = Time.new
    ca.save
    return ca
  end
  
  def self.getCommentsAlert(comment_id, uuid)
    return CommentsAlert.find(:first, :conditions => " comment_id = #{comment_id} and uuid = '#{uuid}' ") 
  end
  
  def self.deleteCommentsAlert(comment_id)
    CommentsAlert.destroy_all(" comment_id = #{comment_id}")
  end
  
end