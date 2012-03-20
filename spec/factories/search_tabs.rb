# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :search_tab do |s|
  s.sequence(:label) {|n| "test-#{n}"}
  s.description "desc"
end

Factory.define :search_tab_subject do |st|
  st.search_tab_id 1
  st.hide false
  st.label "Searchtabsubject"
end

Factory.define :search_tab_filter do |sf|
  sf.search_tab_id 1
  sf.label "filter_label"
  sf.field_filter "title_filter"
end

Factory.define :search_collection_group, :class=>:collection_group do |c|
  c.name "TEST_COLLECTION_GROUP"
  c.full_name "TEST_COLLECTION_GROUP"
  c.enabled true
end
