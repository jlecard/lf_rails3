class Struct::UserSearchesPreferences < ActionWebService::Struct
  
  member :search_tab,   :integer
  member :search_group, :string
  member :search_type,  :string
  
  def initialize
    super
    self.search_tab = ""
    self.search_group = ""
    self.search_type = ""
  end
end
