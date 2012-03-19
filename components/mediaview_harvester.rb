# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
require 'common_harvester'
require 'hidden_indexed_files'
if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
#require ENV['LIBRARYFIND_HOME'] + 'components/mediaview/bpi_connector'
require 'mediaview/bpi_connector'
class MediaviewHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def harvest(collection_id)
    @logger.debug("[MEDIAVIEW] : Entering Mediaview harvester")
    row = Collection.find_by_id(collection_id)
    
    @logger.info("Host : " +row.host + "")
    @logger.info("Db name: " + row.name + "")
    
    # Delete cache for the current collection
    if @local_indexer == 'ferret'
      # TODO
      #          @index = Index::Index.new(:path => LIBRARYFIND_FERRET_PATH, :create => true)
      #          @logger.info("Creating a new Ferret @index")
    elsif @local_indexer == 'solr'
      begin
        @index.send(Solr::Request::Delete.new(:query => 'collection_id:('+row.id.to_s+')'))
        commit
        @logger.info("Cleaning SOLR Harvesting")
      rescue => err
        @logger.error("Error: Cleaning SOLR Harvesting: " + err.message)
      end
    end
    
    begin
      @bpi = Bpi_connector.new
      @bpi.connect_to_postgresql(row.name,row.host,row.user,row.pass)
      @logger.info("Connection done to #{row.host} using #{row.name}")
      _mvrec = @bpi.get_parsed_data(row.id)
      i = 0
      if @local_indexer == 'ferret'
        @logger.info("Started Indexing in #{LIBRARYFIND_FERRET_PATH}")
      elsif @local_indexer == 'solr'
        @logger.info("Started Indexing in #{LIBRARYFIND_SOLR_HARVESTING_URL}")
      end
      @check = HiddenIndexedFiles.new(row.name, @logger)
      @logger.info("check!!!")
      
      _mvrec.each{|_datarow|
        # Saving the document_type
        DocumentType.save_document_type(_datarow.type,row['id'])
        
        ## Indexing data in the search engine
        i += 1
        keyword = _datarow.title + " " + _datarow.creator + " " + _datarow.subject + " " + _datarow.description + " " + _datarow.publisher
        _idD = "#{_datarow.id};#{row['id']}"
        if @local_indexer == 'ferret'
          @index << {:id => _idD, :collection_id => row['id'], :controls_id => _datarow.id, :collection_name => row.name, :title => _datarow.title ,:creator => _datarow.creator, :subject => _datarow.subject, :description => _datarow.description, :publisher => _datarow.publisher, :keyword => keyword, :theme => _datarow.theme, :theme_rebond => _datarow.theme, :category => _datarow.category}
          #puts "Indexed by Ferret........."
        elsif @local_indexer == 'solr'  
          @index.add(:id => _idD, :collection_id => row['id'], :controls_id => _datarow.id, :collection_name => row.name, :title => _datarow.title ,:creator => _datarow.creator, :subject => _datarow.subject, :description => _datarow.description, :publisher => _datarow.publisher, :keyword => keyword, :theme => _datarow.theme, :theme_rebond => _datarow.theme, :category => _datarow.category, :harvesting_date => Time.new)
          
          ptitle = ""
          type = ""
          update_notice(_idD, _datarow.title, _datarow.creator, type, ptitle, Time.new)
          
          #puts "Indexed by Solr........."
        end
        
        @check.checkRow(row.id, _datarow)
        
      }
      @check.validList
      @logger.info("Finished Indexing : #{i} document(s) indexed!!!")
      
      @bpi.disconnect
      
      @logger.info("[portfolio_harvester] Rapport Themes: [Matched: #{@bpi.matched}] [No Matched: #{@bpi.errors}]")
      path = "#{ENV['LIBRARYFIND_HOME']}/log/themes_#{row.name}_not_match_#{Time.now().to_f}.txt"
      is_write = system("echo #{@bpi.indices_no_match.inspect} > #{path}");
      @logger.info("[portfolio_harvester] Rapport Themes: [write_file:#{is_write}] For more details, consulted file: #{path}")
      
    rescue Exception => e
      @logger.error("MEDIAVIEW_HARVESTER: #{e.message}")
      @logger.error("Errors while fetching data in PostgreSQL : #{$!}")
    end
    
    Collection.update(row.id, { :harvested => DateTime::now() })
    
    
    commit if LIBRARYFIND_INDEXER.downcase == 'solr'
    
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      @index.close()
      #reset the @index permissions to 777
      #system('chmod -R 777 ' + LIBRARYFIND_FERRET_PATH);
    end
    @logger.info("Finished processing")
  end
end