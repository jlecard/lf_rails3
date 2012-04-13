#encoding:utf-8
Factory.sequence :dc_identifier do |dc|
  "dc_identifier_#{dc}"
end

Factory.define(:metadatas, :class=>:metadata) do |m|
  m.collection_id 1
  m.dc_identifier {"#{Factory.next(:dc_identifier)}"}
  m.dc_title "johnson title"
  m.dc_creator "johnson creator"
  m.dc_subject "johnson subject"
  m.dc_description "johnson desc"
  m.dc_publisher "johnson"
  m.dc_contributor "johnson"
  m.dc_date Time.now
  m.dc_type "Livre"
  m.dc_format "johnson format"
  m.dc_source "johnson"
  m.dc_relation "johnson"
  m.dc_coverage "johnson"
  m.dc_rights "johnson"
  m.osu_volume "johnson"
  m.osu_issue "johnson"
  m.osu_linking "johnson"
  m.osu_openurl "johnson"
  m.osu_thumbnail "johnson"
  m.dc_language "Français"
end

Factory.define(:portfolio_datas,:class=>:portfolio_data) do |p|
  p.dc_identifier {"#{Factory.next(:dc_identifier)}"}
  p.issn "johnson"
  p.isbn "johnson"
  p.call_num "johnson"
  p.last_issue "johnson"
  p.audience "johnson"
  p.genre "johnson"
  p.publisher_country "johnson"
  p.copyright "johnson"
  p.display_group "johnson"
  p.broadcast_group "johnson"
  p.license_info "johnson"
  p.commercial_number "johnson"
  p.binding "johnson"
  p.theme "johnson"
  p.is_available true
  p.indice "johnson"
  p.display_groups "johnson"
  p.issues "johnson"
  p.issue_title "johnson"
  p.conservation "johnson"
end

Factory.define(:volumes,:class=>:volume) do |v|
  v.collection_id 1
  v.call_num "johnson"
  v.availability "online"
  v.location "johnson"
  v.label "johnson"
  v.link_label "johnson"
  v.launch_url "johnson"
  v.link "johnson"
  v.support "johnson"
  v.document_id 800
  v.barcode 123456
  v.source "johnson"
end
