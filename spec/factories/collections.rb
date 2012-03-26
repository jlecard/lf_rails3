Factory.sequence :coll_name do |n|
  "collection_#{n}"
end

Factory.define :collection_seq, :class=>:collection do |c|
  c.name {"#{Factory.next(:coll_name)}"}
  c.conn_type "oai"
  c.host "http://host"
  c.mat_type "Article"
end


