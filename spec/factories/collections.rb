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
  c.proxy true
  c.record_schema "MARC21"
  c.definition "author=100a;author=700a;creator=100a;creator=100a;atitle=245a;link=773t;link=773g;mat_type=72a;subject=606a;subject=650a;issn=022a;note=546a;note=520a;note=520b;date=903a;pub=260a;cnum=500a;static=856u;volume=945m;volume=945d;volume=945n;page=945p;direct_url=856u"
  c.definition_search "creator=1003;author=1003;subject=21;issn=8;isbn=7;callnum=16;publisher=1018;title=4;keyword=1016"
end

Factory.define :em_consulte_collection, :class=>:collection do |c|
  c.name "emconsulte"
  c.alt_name "emconsulte"
  c.conn_type "connector"
  c.host "http://www.em-consulte.com"
  c.oai_set "Emconsulte"
  c.proxy true
  c.url "http://www.em-consulte.com"
end

Factory.define :europresse_collection, :class=>:collection do |c|
  c.name "europresse"
  c.alt_name "europresse"
  c.conn_type "connector"
  c.host "http://www.bpe.europresse.com/ip/intro.asp?user=pompi"
  c.oai_set "Europresse"
  c.proxy true
  c.post_data "ctl00$Main$ucLoginBiblio$txbUserName=pompi|ctl00$Main$ucLoginBiblio$txbPassword=biblio"
end

Factory.define :classiques_garnier_collection, :class=>:collection do |c|
  c.name "classiques_garnier"
  c.alt_name "classiques_garnier"
  c.conn_type "connector"
  c.host "http://www.classiques-garnier.com"
  c.url "http://www.classiques-garnier.com"
  c.oai_set "ClassiquesGarnier"
  c.proxy true
end

Factory.define :crawler_collection, :class=>:collection do |c|
  c.name "crawler"
  c.alt_name "crawler"
  c.conn_type "connector"
  c.host "http://10.1.2.129:8180/solr/crawler-bpi"
  c.oai_set "Crawler"
  c.proxy true
end

Factory.define :oxford_art_collection, :class=>:collection do |c|
  c.name "oxford_art"
  c.alt_name "oxford_art"
  c.conn_type "connector"
  c.record_schema "Oxfordgeneric"
  c.oai_set "oxford"
  c.host "http://www.oxfordartonline.com"
  c.url "http://www.oxfordartonline.com"
  c.vendor_url "http://www.oxfordartonline.com"
  c.proxy true
end

Factory.define :oxford_dnb_collection, :class=>:collection do |c|
  c.name "oxford_dnb"
  c.alt_name "oxford_dnb"
  c.conn_type "connector"
  c.record_schema "oxforddnb"
  c.oai_set "oxford"
  c.host "http://www.oxforddnb.com"
  c.url "http://www.oxforddnb.com"
  c.vendor_url "http://www.oxforddnb.com"
  c.proxy true
end

Factory.define :factiva_collection, :class=>:collection do |c|
  c.name "factiva"
  c.alt_name "factiva"
  c.conn_type "connector"
  c.post_data "XSID=S00YdBfZWva5DEs5DEoMDUpMD2pOTVyMHn0YqYvMq382rbRQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQQAA"
  c.oai_set "Factiva"
  c.host "https://global.factiva.com/fr/sess/login.asp"
  c.url "http://global.factiva.com"
  c.vendor_url "http://global.factiva.com"
  c.proxy true
end

Factory.define :portfolio_collection, :class=>:collection do |c|
  c.name "portfolio"
  c.alt_name "portfolio"
  c.conn_type "connector"
  c.oai_set "Portfolio"
  c.host "10.1.2.100"
  c.user "postgres"
  c.pass "postgresbpi"
  c.proxy false
end



