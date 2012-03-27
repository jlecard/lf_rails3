Factory.sequence :coll_name do |n|
  "collection_#{n}"
end

Factory.sequence :coll_alt_name do |n|
  "alt_#{n}"
end

Factory.define :collection_seq, :class=>:collection do |c|
  c.name {"#{Factory.next(:coll_name)}"}
  c.conn_type "oai"
  c.host "http://host"
  c.mat_type "Article"
end

Factory.define :collection_seq_with_alt, :class=>:collection do |c|
  c.name {"#{Factory.next(:coll_name)}"}
  c.alt_name {"#{Factory.next(:coll_alt_name)}"}
  c.conn_type "oai"
  c.host "http://host"
  c.mat_type "Article"
end


