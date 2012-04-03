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

Factory.define :z3950_collection, :class=>:collection do |c|
  c.name "Z3950"
  c.alt_name "Z3950"
  c.conn_type "z3950"
  c.host "lx2.loc.gov:210/LCDB"
  c.proxy false
  c.record_schema "MARC21"
  c.definition "author=100a;author=700a;creator=100a;creator=100a;atitle=245a;link=773t;link=773g;mat_type=72a;subject=606a;subject=650a;issn=022a;note=546a;note=520a;note=520b;date=903a;pub=260a;cnum=500a;static=856u;volume=945m;volume=945d;volume=945n;page=945p;direct_url=856u"
  c.definition_search "creator=1003;author=1003;subject=21;issn=8;isbn=7;callnum=16;publisher=1018;title=4;keyword=1016"
end


