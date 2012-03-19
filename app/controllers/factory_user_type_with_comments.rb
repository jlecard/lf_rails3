class FactoryUserTypeWithComments < ActiveRecord::Base
  
  def self.createUserTypeWithComments(user_type, comments)
    
    if user_type.nil?
      return nil
    end
    
    ut = Struct::UserTypeWithComments.new()
    ut.user_type = user_type;
    ut.comments_count = comments.size;
    ut.comments = comments;
    return ut
  end
  
end