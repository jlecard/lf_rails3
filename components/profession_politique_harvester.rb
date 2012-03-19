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
require 'profession_politique'

class ProfessionpolitiqueHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def harvest(collection_id=nil, diff=true)
    row = Collection.find_by_id(collection_id) #dbh.query(query);
    _start = nil
    
    @logger.info("Host" + row.host)
    @logger.info("Db Name :" + row.name)
    @logger.info(row.is_parent.to_s)
    _start = Time.now()
    @logger.info("Start indexing " + row.host.to_s)
    
    n = 0
    documents = Array.new
    if row.proxy == 1
      yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
      _host = yp['PROXY_HTTP_ADR']
      _port = yp['PROXY_HTTP_PORT']
      @logger.debug("#{row.name} use proxy: #{_host} with port #{_port} ")
    else
      _host = nil
      _port = nil
    end
    
    ProfessionPolitique::parse(@logger, _host, _port).each do |rec|
      @logger.debug(rec.title)
      dctitle = rec.title
      dccreator = ""
      dcsubject = "#{rec.type} : #{rec.subject}"
      dcdescription = "#{rec.title} : #{rec.description}"
      dcpublisher = rec.publisher
      dccontributor = ""
      dcdate = rec.date
      dctype = DocumentType.save_document_type("Article",row.id)
      dcformat = ""
      dcidentifier = rec.id
      dcsource = rec.publisher
      dcrelation = ""
      dccoverage = ""
      dcrights = ""
      dcthumbnail = ""
      keyword = ""
      dcvolume = ""
      osulinking = rec.link
      
      keyword = "#{dctitle} #{dcdescription} #{dcpublisher} #{dctype}"
      keyword.strip!
      
      
      ctitle = "#{dcpublisher} : #{dctitle}"
      # Check if a record with the same oai_identifier already exists before
      if Control.find(:first, :conditions => {:oai_identifier => dcidentifier.to_i, :collection_id => row.id.to_i}).nil?
        _control = Control.new(
                               :oai_identifier => dcidentifier, 
                               :title => ctitle, 
                               :collection_id => row.id, 
                               :description => dcdescription, 
                               :url => rec.link, 
                               :collection_name => row.name
        )
        _control.save!()
        last_id = _control.id
        
        _metadata = Metadata.new(
                                 :collection_id => row.id, 
                                 :controls_id => last_id, 
                                 :dc_title => dctitle, 
                                 :dc_creator => dccreator, 
                                 :dc_subject => dcsubject,
                                 :dc_description => dcdescription, 
                                 :dc_publisher => dcpublisher, 
                                 :dc_contributor => dccontributor, 
                                 :dc_date => dcdate, 
                                 :dc_type => dctype, 
                                 :dc_format => dcformat, 
                                 :dc_identifier => dcidentifier, 
                                 :dc_source => dcsource, 
                                 :dc_relation => dcrelation, 
                                 :dc_coverage => dccoverage, 
                                 :dc_rights => dcrights, 
                                 :osu_volume => dcvolume,
                                 :osu_thumbnail => dcthumbnail,
                                 :osu_linking => osulinking
        )
        _metadata.save!()
        
        # Saving the document_type
        DocumentType.save_document_type(dctype,row.id)  
        
        _stopTimeBase = Time.now()
        main_id = _metadata.id
        _idD = "#{dcidentifier};#{row.id}"
        
        if @local_indexer == 'ferret'
          @index << {:id => _idD, :collection_id => row.id, :collection_name => row.name, :controls_id => last_id, :title => dcpublisher, :subject => dcsubject, :creator => dccreator + " " + dccontributor, :keyword => keyword, :publisher => dcpublisher}           
        elsif @local_indexer == 'solr'
          documents.push({:id => _idD, :collection_id => row.id, :collection_name => row.name, :controls_id => last_id, :title => dctitle ,:subject => dcsubject, :creator => dccreator, :keyword => keyword, :publisher => dcpublisher, :document_type => dctype, :harvesting_date => Time.new})
          if n%100==0
            @index.add(documents)
            documents.clear
            begin 
              commit
            rescue exception => e
              @logger.error("Exception committing to solr - removing database entries...")
              Control.delete_all(:conditions=>{:oai_identifier => oai_identifier, :collection_id => row.id})
              Metadata.delete_all(:conditions=>{:control_id => last_id, :collection_id => row.id})
            end
          end
          n+= 1  
          end
        else
          @logger.info("[#{self.class}]: A record with oai_identifier #{dcidentifier} already exists")
          next
        end ## end if control already exists
      end ## end of ProfessionPolitique::parse.each
      
      @index.add(documents) if !documents.empty?
      
      commit if LIBRARYFIND_INDEXER.downcase == 'solr'
      @logger.info("Finished indexing : #{n} documents indexed !!!")
      
      Collection.update(row.id, { :harvested => DateTime::now() })
      
      @logger.info("###### Total time on Profession Politique :" + (Time.now() - _start).to_s + " seconds. #######")
      
      #close the ferret indexes
      @index.close() if LIBRARYFIND_INDEXER.downcase == 'ferret'
      
      #reset the index permissions to 777
      #  system('chmod -R 777 ' + LIBRARYFIND_FERRET_PATH);
      #print "Finished processing\n"
      
    end
  end
