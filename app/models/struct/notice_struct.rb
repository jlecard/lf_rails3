class Struct::NoticeStruct < ActionWebService::Struct
  
  member :identifier, :string
  member :dc_title, :string
  member :dc_author, :string  
  member :dc_type, :integer
  member :isbn, :string
  member :ptitle, :string  
  member :notes_count, :integer
  member :notes_avg, :float
  member :comments_count, :integer
  member :comments_view_count, :integer
  member :com_note, []
  member :com_user, []
  member :lists_count, :integer
  member :lists_list, []
  member :tags_count, :integer
  member :object_tag_struct, Struct::ObjectTagStruct
  member :is_available, :integer
  member :examplaires, [Struct::Examplaire]
  
  def initialize
    super
    self.identifier = ""
    self.dc_title = ""
    self.dc_author = ""  
    self.dc_type = ""
    self.isbn = ""
    self.ptitle = ""
    self.notes_count = 0
    self.notes_avg = 0.0
    self.comments_count = 0
    self.comments_view_count = 0
    self.com_note = []
    self.com_user = []
    self.lists_list = []
    self.lists_count = 0
    self.tags_count = 0
    self.object_tag_struct = nil
    self.is_available = 0
    self.examplaires = []
  end
  
end
