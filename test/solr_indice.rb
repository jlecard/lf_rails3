require 'solr'
include Solr

conn = Solr::Connection.new('http://10.1.2.114:8080/solr',{:timeout=>10000})

_response = conn.optimize
p _response