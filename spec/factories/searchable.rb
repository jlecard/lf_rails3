Factory.define :collection do |c|
  c.name "keesings"
  c.alt_name "keesings"
  c.host "http://www.keesings.com"
  c.record_schema "Keesing"
  c.oai_set "Keesing"
  c.conn_type "connector"
end

Factory.define :collection_group_member do |member|
  member.filter_query ""
end
