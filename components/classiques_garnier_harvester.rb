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
require 'classiques_garnier'
require 'marc'

class ClassiquesGarnierHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def to_utf8(string)
    if !string.blank?
        #return Iconv.conv('UTF-8', 'ISO-8859-1', string)
        return string
    end
  end
  
  def harvest(collection_id=nil, diff = false)
    row = Collection.find_by_id(collection_id)
    _start = nil
    
    @logger.info("Host" + row.host)
    @logger.info("Db Name :" + row.name)
    @logger.info(row.is_parent.to_s)
    _start = Time.now()
    @logger.info("Start indexing " + row.host.to_s)
    #Delete solr index for the current collection
    clean_solr_index(row.id)
    # Clear MySql data tables
    clean_sql_data(row.id)
    
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
    
    download_dir = "#{RAILS_ROOT}/components/classiques_garnier"
    #ClassiquesGarnier.download_marc_files(download_dir, _host, _port, @logger)
    readers = ClassiquesGarnier.read_marc_files(download_dir, @logger)
    if !readers.nil?
      begin
        readers.each do |reader|
          if !reader.nil?
            tags = ['001','245','100','440','040','260','650','490','776','856']
            
            for rec in reader
              dcidentifier = ""
              dctitle = Array.new
              dccreator = Array.new
              dcsubject = Array.new
              dcpublisher = Array.new
              dccontributor = Array.new
              dcrelation = Array.new
              dcdate = Array.new
              dctype = Array.new
              dccoverage = Array.new
              osulinking = Array.new
              
              fields = rec.find_all { | field | tags.include?(field.tag) }
              fields.each do |field|
                case field.tag
                  when '001'
                  dcidentifier = field.value
                  when '245'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dctitle.push(to_utf8(subfield.value)) 
                    end
                  end
                  when '100'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dccreator.push(to_utf8(subfield.value)) 
                    end
                  end
                  when '440'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dcsubject.push(to_utf8(subfield.value)) 
                    end
                  end
                  when '040'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dcpublisher.push(to_utf8(subfield.value)) 
                    end
                  end
                  when '260'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dccontributor.push(to_utf8(subfield.value)) 
                    elsif subfield.code == "b"
                      dccreator.push(to_utf8(subfield.value))
                    elsif subfield.code == "c"
                      dcdate.push(to_utf8(subfield.value))
                    end
                  end
                  when '650'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dctype.push(to_utf8(subfield.value)) 
                    end
                  end
                  when '490'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dcrelation.push(to_utf8(subfield.value)) 
                    end
                  end
                  when '776'
                  field.subfields.each do |subfield|
                    if subfield.code == "d"
                      dccoverage.push(to_utf8(subfield.value)) 
                    end
                  end
                  when '856'
                  field.subfields.each do |subfield|
                    if subfield.code == "u"
                      osulinking.push(to_utf8(subfield.value)) 
                    end
                  end
                end
                
              end
              
              dctitle = dctitle.join(";")
              dccreator = dccreator.join(";")
              dcsubject = dcsubject.join(";")
              dcpublisher = dcpublisher.join(";")
              dccontributor = dccontributor.join(";")
              dcdate = dcdate.join(";")
              dctype =  DocumentType.save_document_type(dctype.join(";"),row.id)  
              dcrelation = dcrelation.join(";")
              dccoverage = dccoverage.join(";")
              osulinking = osulinking.join(";")
              dcdescription = "#{dctitle} ; #{dcsubject}"
              
              dcsource = dcpublisher
              
              dcrights = ""
              dcthumbnail = ""
              keyword = ""
              dcvolume = ""
              
              keyword = "#{dctitle} #{dcdescription} #{dcpublisher} #{dctype} #{dccreator} #{dccontributor}"
              keyword.strip!
              
              
              ctitle = "#{dcpublisher} : #{dctitle}"
              # Check if a record with the same oai_identifier already exists before
              if Control.find(:first, :conditions => {:oai_identifier => dcidentifier, :collection_id => row.id.to_i}).nil?
                _control = Control.new(
                                       :oai_identifier => dcidentifier, 
                                       :title => ctitle, 
                                       :collection_id => row.id, 
                                       :description => dcdescription, 
                                       :url => osulinking, 
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
                                         :dc_format => "", 
                                         :dc_identifier => dcidentifier, 
                                         :dc_source => dcsource, 
                                         :dc_relation => dcrelation, 
                                         :dc_coverage => dccoverage, 
                                         :dc_rights => dcrights, 
                                         :osu_volume => "",
                                         :osu_thumbnail => dcthumbnail,
                                         :osu_linking => osulinking
                )
                _metadata.save!()
                

                
                _stopTimeBase = Time.now()
                main_id = _metadata.id
                _idD = "#{dcidentifier};#{row.id}"
                
                if @local_indexer == 'ferret'
                  @index << {:id => _idD, :collection_id => row.id, :collection_name => row.name, :controls_id => last_id, :title => dcpublisher, :subject => dcsubject, :creator => dccreator + " " + dccontributor, :keyword => keyword, :publisher => dcpublisher}           
                elsif @local_indexer == 'solr'
                  documents.push({:id => _idD, :collection_id => row.id, 
                                :collection_name => row.name, :controls_id => last_id,  
                                :title => dctitle, :subject => dcsubject, 
                                :creator => "#{dccreator} #{dccontributor}", :autocomplete_creator =>"#{dccreator} #{dccontributor}", :keyword => keyword, 
                                :publisher => dcpublisher, :document_type => dctype, 
                                :harvesting_date => Time.new})
                  if n%100==0
                    @index.add(documents)
                    documents.clear
                    begin 
                      commit
                    rescue Exception => e
                      @logger.error("Exception committing to solr - removing database entries...")
                      Control.delete_all(:conditions=>{:oai_identifier => dcidentifier, :collection_id => row.id})
                      Metadata.delete_all(:conditions=>{:control_id => last_id, :collection_id => row.id})
                    end
                  end
                  n+= 1  
                  end
                else
                  @logger.info("[#{self.class}]: A record with oai_identifier #{dcidentifier} already exists")
                end ## end if control already exists
              end ## end !reader.nil?
            end ## end of reader.each
          end ## end of  readers.each
        rescue Exception=>e
          logger.error(e.message)
          logger.error(e.backtrace.join("\n"))
        end  
      else
        @logger.info(reader)
      end ## end of if ! readers.nil?
      
      @index.add(documents) if !documents.empty?
      
      commit if LIBRARYFIND_INDEXER.downcase == 'solr'
      @logger.info("Finished indexing : #{n} documents indexed !!!")
      
      Collection.update(row.id, { :harvested => DateTime::now() })
      ClassiquesGarnier.clear_downloaded_files(download_dir, @logger)
      @logger.info("###### Total time on Classiques Garnier :" + (Time.now() - _start).to_s + " seconds. #######")
      
      #close the ferret indexes
      @index.close() if LIBRARYFIND_INDEXER.downcase == 'ferret'
      
    end
    
  end
