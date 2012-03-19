require '../components/common_harvester'

class CleanSolrIndex < CommonHarvester
  
  def initialize
    super
  end
  
  def delete_solr_index(collection_id)
    clean_solr_index(collection_id)
    clean_sql_data(collection_id)
    reset_harvest_date(collection_id)
  end
  
  def clean_all_oai
    query = "select * from collections where conn_type = 'oai'"
    collections = Collection.find_by_sql(query)
    collections.each do |collection|
      clean_solr_index(collection.id)
      clean_sql_data(collection.id)
      reset_harvest_date(collection.id)
    end
  end
  
  :private
  def reset_harvest_date(collection_id)
    col = Collection.find_by_id(collection_id)
    col.harvested = '1970-01-01'
    col.save
  end
end

csi = CleanSolrIndex.new
if $*.size > 0 and ARGV[0].match(/\d+/)
  csi.delete_solr_index ARGV[0]
elsif $*.nil? or $*.size == 0
  csi.clean_all_oai
end
