class FactoryNotice < ActiveRecord::Base
  
  def self.createNotice(notice, ex = nil, uuid = nil)
    
    item = Struct::NoticeStruct.new()
    
    item.identifier = "#{notice.doc_identifier}#{ID_SEPARATOR}#{notice.doc_collection_id}"
    item.dc_title = notice.dc_title
    item.isbn = notice.isbn
    item.ptitle = notice.ptitle
    item.dc_author = notice.dc_author
    item.dc_type = notice.dc_type
    
    item.notes_avg = notice.notes_avg
    item.notes_count = notice.notes_count
    oc = ObjectsCount.getObjectCountById(ENUM_NOTICE, item.identifier)
    if(!oc.nil?)
      item.tags_count = oc.tags_count_public
      item.comments_count = oc.comments_count_public
      item.lists_count = oc.lists_count_public
      item.lists_list = List.getNoticeLists(notice.doc_identifier)
    end
    if (!uuid.nil?)
      priv_count = Comment.getUserPrivateCommentsCount(item.identifier, 1, uuid)
      if (!priv_count.nil?)
        item.comments_view_count =  item.comments_count + priv_count
      end
    else
      item.comments_view_count =  item.comments_count
    end
    
    notes = Note.getCountCommentsByNote(item.identifier, 1, uuid)
    if(!notes.nil?)
      item.com_note = notes
    end
    
    user_type = Comment.getCountCommentsByUserType(item.identifier, 1, uuid)
    if(!user_type.nil?)
      item.com_user = user_type
    end
    
    item.examplaires = ex
#    item.is_available = notice.is_available
    
    return item
  end
  
  def self.createSimpleNotice(notice, object_tag_struct = nil)
    item = Struct::NoticeStruct.new()
    item.identifier = "#{notice.doc_identifier}#{ID_SEPARATOR}#{notice.doc_collection_id}"
    item.dc_title = notice.dc_title
    item.ptitle = notice.ptitle
    item.object_tag_struct = object_tag_struct
    #item.is_available = notice.is_available
    
    return item
  end
end