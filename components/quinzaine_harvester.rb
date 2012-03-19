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

class QuinzaineRecord
  attr_accessor :volume, :date, :coverage, :subject, :title, :ref_title, :ref_contributors, :ref_translators, :ref_author, :ref_publisher, :author, :url1, :url2
  
  def normalize
    _string = nil
    instance_variables.each do |var|
      if !instance_variable_get("#{var}").blank?
        instance_variable_set("#{var}", instance_variable_get("#{var}").to_s.gsub(" @ ", ";"))
        _string = Iconv.conv('UTF-8', 'ISO-8859-1', instance_variable_get("#{var}")) unless !instance_variable_get("#{var}").kind_of?(String)
        instance_variable_set("#{var}", _string) unless !_string 
      end
    end
  end
  
end

class QuinzaineHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def harvest(collection_id,diff=true)
    row = Collection.find_by_id(collection_id) #dbh.query(query);
    _start = Time.now()
    @logger.info("Host" + row.host)
    @logger.info("Db Name :" + row.name)
    @logger.info(row.is_parent.to_s)
    
    #Delete cache for the current collection
    if @local_indexer == 'ferret'
      # TODO
      @index = Index::Index.new(:path => LIBRARYFIND_FERRET_PATH, :create => true)
      @logger.info("Creating a new Ferret index")
    elsif @local_indexer == 'solr'
      clean_solr_index(row.id)
      commit
      @logger.info("Cleaning SOLR Harvesting index")
    end
    
    @logger.info("Deleting LibraryFind content metadatas for collection #{row.id}")
    clean_sql_data(row.id)
    
    @logger.info("Start indexing " + row.host.to_s)
    
    n = 1
    documents = Array.new
    File.open(row.host).each do |rec|
      dataArray =  Array.new
      i = 0         
      rec.split("\t").each do |element|
        element.chomp!
        dataArray.insert(i,element)
        i+= 1
      end
      
      record = QuinzaineRecord.new
      record.volume = dataArray[0] 
      record.date = UtilFormat.normalizeDate(dataArray[1])
      record.coverage = dataArray[2]
      record.subject = dataArray[3]
      record.title = dataArray[5]
      record.ref_title = dataArray[6]
      record.ref_contributors = dataArray[7]
      record.ref_translators = dataArray[8]
      record.ref_author = dataArray[9]
      record.ref_publisher = dataArray[10]
      record.author = dataArray[11]
      record.url1 = dataArray[12]
      record.url2 = dataArray[19]
      record.normalize
      dctitle = ""
      dccreator = ""
      dcsubject = ""
      dcdescription = ""
      dcpublisher = "La quinzaine littéraire"
      dccontributor = ""
      dcdate = "" 
      dctype = "" 
      dcformat = ""
      dcidentifier = ""
      dcsource = ""
      dcrelation = "" 
      dccoverage = ""
      dcrights = ""
      dcthumbnail = ""
      keyword = ""
      dcvolume = ""
      osulinking = ""
      
      dccreator = record.author
      dctitle = record.title
      dcsubject = record.subject
      dcdescription = "#{record.subject};#{record.title};#{record.author};#{record.ref_author};#{record.ref_title}"
      dcdate = record.date
      dccoverage = record.coverage
      dcvolume = record.volume
      dccontributor = "#{record.ref_contributors}"
      
      if !record.url2.blank?
        dcidentifier = record.url2.gsub("_","").gsub(".html","")
      end
      
      dctype = DocumentType.save_document_type("Article",row.id)
      dcsource = 'Quinzaine littéraire'

      keyword = "#{dccreator} #{dcdescription} #{dcpublisher} #{dctype}"
      keyword.strip!
      ctitle = "#{dcpublisher} : #{dctitle}"
      _control = Control.new(
                                   :oai_identifier => dcidentifier, 
                                   :title => ctitle, 
                                   :collection_id => row.id, 
                                   :description => dcdescription, 
                                   :url => dcidentifier, 
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
      #_idD = dcidentifier
      
      if @local_indexer == 'ferret'
        @index << {:id => _idD, :collection_id => row.id, :collection_name => row.name, :controls_id => last_id, :title => dcpublisher, :subject => dcsubject, :creator => dccreator + " " + dccontributor, :keyword => keyword}           
      elsif @local_indexer == 'solr'
        documents.push({:id => _idD, :collection_id => row.id, :collection_name => row.name, :controls_id => last_id, :title => dctitle ,:subject => dcsubject, :creator => dccreator, :keyword => keyword, :document_type => dctype, :harvesting_date => Time.new})
        
        ptitle = ""
        update_notice(_idD, dctitle, dccreator, dctype, ptitle, Time.new)
        
        if n%100==0
            # on index tous les 100 docs
          @index.add(documents)
          documents.clear
          
          commit if n%10000==0
          n+= 1
        end
      end
    end
    
    @logger.info("Finished indexing : #{n} documents indexed !!!")
    
    if !documents.empty?
      @index.add(documents)
    end
    Collection.update(row.id, { :harvested => DateTime::now() })
    commit if LIBRARYFIND_INDEXER.downcase == 'solr'
    
    @logger.info("###### Total time on quinzaine litteraire :" + (Time.now() - _start).to_s + " seconds. #######")
    
    #close the ferret indexes
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      @index.close()
    end
    
    #reset the index permissions to 777
    #  system('chmod -R 777 ' + LIBRARYFIND_FERRET_PATH);
    #print "Finished processing\n"
  end
end
