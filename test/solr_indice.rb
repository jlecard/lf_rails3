require 'solr'
include Solr

conn = Solr::Connection.new('http://localhost:8080/solr')

_response = conn.query('( indice:(840\"18\") )')
@total_hits = _response.total_hits
p @total_hits
_query = Array.new
_response.each do |hit|
  if _query != ""
    p(hit["controls_id"].to_s)
  end
end