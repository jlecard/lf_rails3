# $Id: collection.rb 1293 2009-03-23 06:06:27Z reeset $

# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

class Collection < ActiveRecord::Base
  
  validates_presence_of :name, :conn_type, :host, :mat_type
  
  validates_uniqueness_of :name
  
  has_many :cached_record
  has_many :harvest_schedule
  has_many :collection_group_members
  has_many :collection_groups, :through => :collection_group_members
  has_many :metadata
  has_many :control
  has_many :volume
  belongs_to :manage_droit
  
  def self.get_item(id) 
    begin
      objRec = Collection.find(id)
      return objRec.alt_name
    rescue
      return nil
    end
  end 
  
  def self.get_all()
    return Collection.find(:all)
  end
  
  def self.getCollectionById(collection_id)
    return Collection.find(collection_id)
  end
  
  def self.getCollectionsIds(collections_permissions)
    collections_ids = Array.new
    collections_permissions.each do |cp|
      collections_ids << cp.id_collection 
    end
    if(collections_ids.size==0)
      collections_ids << ""
    end
    return collections_ids
  end
  
  def self.find_resources(sets, no_externe = false)
    coll = ""
    groups = ""

    sql = "SELECT DISTINCT collection_id,filter_query FROM collection_group_members  WHERE  "  
    sets.split(",").each do |item|
      if item.slice(0,1)=='c'
        coll << item.slice(1,item.length-1) + ","
        logger.debug("[Collection][find_resources] coll = #{coll.inspect}")  
      else
        groups << item.slice(1,item.length-1) + ","
      end
    end
    
    if coll.length > 0
      coll = "collection_id IN (" + coll.chomp(",") + ")"
    end
    
    if groups.length > 0
      groups = "collection_group_id IN (" + groups.chomp(",") + ")"
    end
    
    if coll.length > 0 && groups.length > 0
      sql << coll + " OR " + groups
    elsif coll.length == 0
      sql << groups
    else
      sql << coll
    end
    logger.debug("[Collection][find_resources] sql = #{sql}")
    c_ids = CollectionGroupMember.find_by_sql(sql)
    results = []
    c_ids.each do |item|
      begin
        collections = Collection.find(item.collection_id)
        if (no_externe and !collections.nil? and collections.is_external)
          logger.warn("[Collection][find_resources] Collection #{collections.id} - #{collections.alt_name} is ignored => no flux rss for collection externe")
          collections = nil
        end
      rescue => e
        logger.error("[Collection][find_resources] error : #{e.message}")
        collections = nil
      end
      if collections!=nil
        if collections.filter_query == nil
          collections.filter_query = item.filter_query
        else
          collections.filter_query = collections.filter_query + " " + item.filter_query
        end
        results << collections
      end
    end
    return results  
  end
  
  def self.find_resources_b (sets)
    collections = Collection.find(:all, :order => 'conn_type DESC')
    results = []
    
    collections.each do |coll|
      sets.split(';').each do |set|
        if set.length > 0
          if coll.name == set
            results << coll
          elsif coll.virtual == set   
            results << coll
          end
        end
      end
    end
    results
  end
  
  def self.find_by_type (ltype)
    return Collection.find(:all, :conditions => "conn_type='oai'")
  end
  
  def zoom_params (qtype)
    objProxy = Proxy.new()
    if LIBRARYFIND_USE_PROXY == true && self.proxy.to_s == '1'
      self.vendor_url = objProxy.GenerateProxy(self.vendor_url)
    end
    
    p = {
      'host' => find_protocol,
      'port'=> find_port,
      'name'=> find_db,
      'syntax'=> self.record_schema,
      'type' => qtype[0],
      'username'=> self.user,
      'password'=> self.pass,
      'start' => 1,
      'max' => 10,
      'url' => self.url,
      'def' => self.definition,
      'mat_type' => self.mat_type,
      'vendor_name' => self.alt_name,
      'vendor_url' => self.vendor_url,
      'isword' => self.isword,
      'proxy' => self.proxy,
      'bib_attr' => self.bib_attr
    }
    
    
    
  end
  
  def find_protocol
    protocol = self.host.slice(0, self.host.index(':')).strip
  end
  
  def find_port
    port = self.host.slice(self.host.index(':') + 1, (self.host.index('/') - (self.host.index(':') + 1 )))
    port.to_i
  end
  
  def find_db
    #_db = _row['host'].slice(_row['host'].index('/')+1, _row['host'].length-(_row['host'].index('/')+1))
    db = self.host.slice(self.host.index('/') + 1, self.host.length - self.host.index('/') + 1)      
    db = db.strip
  end  
  
  def is_private
    false
  end
  
  def is_external
    return ['z3950', 'opensearch', 'sru', 'connector'].include? conn_type
  end  
  
  def get_harvested_formated
    if !self.harvested.nil?
      return self.harvested.strftime('%d/%m/%y %H:%M')
    else
      return ""
    end
  end
  
  
  protected
  
  def validate
    # We shouldn't validate this.  It should be free text.
    # where we list common values we support.
    # These should be enumerated in a related table
    #errors.add(:record_schema, "Invalid record schema") if not 
    #  ['Marc21', 'MARC21', 'MARC21;xml', 'oai_dc', 'SUTRS'].include? record_schema
    
    # As should these
    #    errors.add(:mat_type, "Invalid material type") if not
    #      ['Article', 'Book', 'Finding Aid', 'Image', 'Newspaper', 'Internet'].include? mat_type
    
    # And these
    valid_connections = ['z3950', 'oai', 'opensearch', 'sru', 'mediaview', 'ged', 'portfolio','quinzaine','ProfessionPolitique','connector']
    if !valid_connections.include? conn_type
      errors.add(:conn_type, "Invalid connection type. Valid connections are #{valid_connections.join(', ').chomp(', ')}")
    end
  end
end
