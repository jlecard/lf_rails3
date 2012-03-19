class FactoryList < ActiveRecord::Base
  
  def self.createList(list, community_user, uuid, detailed_list = false, object_tag_struct = nil, tags_count = 0, commments_count = 0, page = DEFAULT_PAGE_NUMBER_NOTICE, notice_max = DEFAULT_MAX_NOTICE)
    if list.nil?
      return nil
    end
    
    l = Struct::ListUser.new()
    l.id = list.id.to_s
    l.title = list.title
    l.ptitle = list.ptitle
    l.description = list.description
    l.object_tag_struct = object_tag_struct
    l.state = list.state
    if(!community_user.nil?)
      l.uuid = community_user.uuid;
      l.user_name = community_user.name;
    end
    l.size = list.list_user_records.size()
    if(detailed_list)
      l.tags_count = tags_count
      l.comments_count = commments_count
      
      if (!uuid.nil?)
        priv_count = Comment.getUserPrivateCommentsCount(l.id, 2, uuid)
        if (!priv_count.nil?)
          l.comments_view_count =  l.comments_count + priv_count
        end
      else
        l.comments_view_count =  l.comments_count
      end
      
      l.date_updated = list.updated_at
      l.date_created = list.created_at
      
      if page.nil?
        page = DEFAULT_PAGE_NUMBER_NOTICE
      end
      
      if notice_max.nil?
        notice_max = DEFAULT_MAX_NOTICE
      end
      
      offset = (page.to_i-1)*notice_max.to_i;
      
      items = list.list_user_records.all(:limit => notice_max, :offset => offset, :order => "rank ASC")
      tmp = []
        
      docs_to_check = Hash.new();
           
      if !items.empty?
        items.each do |item|
          if !docs_to_check.has_key?(item.doc_collection_id)
            docs_to_check[item.doc_collection_id] = []
          end
          docs_to_check[item.doc_collection_id] << item.doc_identifier
        end
      end
      
      # Get examplaires from distant DB as Hash
      docs_examplaires = Hash.new()
      docs_examplaires = PortfolioSearchClass.getExamplairesForNotices(docs_to_check)
      if !items.empty?
        items.each do |item|
          doc_id = "#{item.doc_identifier}#{ID_SEPARATOR}#{item.doc_collection_id}"
          examplaires = (docs_examplaires.size != 0) ? docs_examplaires[doc_id][:examplaires] : nil
          dispo = (docs_examplaires.size != 0) ? true : false
          tmp << createListItem(item, dispo, examplaires)
        end
      end
      l.notices = tmp
    end    
    return l
  end
  
  def self.createListItem(list_user_records, is_available = false, examplaires = nil)
    if list_user_records.nil? or list_user_records.user_record.nil?
      return nil
    end
    
    notice = list_user_records.user_record.notice
    
    if notice.nil?
      return nil
    end
    item = Struct::ListItem.new()
    item.id = list_user_records.id.to_s
    item.rank = list_user_records.rank
    item.identifier = "#{notice.doc_identifier}#{ID_SEPARATOR}#{notice.doc_collection_id}"
    item.title = notice.dc_title
    item.isbn = notice.isbn
    item.ptitle = notice.ptitle
    item.author = notice.dc_author
    item.type = notice.dc_type
    item.notes_avg = notice.notes_avg
    item.notes_count = notice.notes_count
    oc = ObjectsCount.getObjectCountById(ENUM_NOTICE,"#{notice.doc_identifier},#{notice.doc_collection_id}")
    item.comments_count = oc.comments_count_public
    item.is_available = is_available
    item.examplaires = examplaires
    return item
  end

end