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

class GedRecord
  attr_accessor :nuid, :ndoc, :dons, :dcxf, :dmxf, :dat1, :dat2, :cont, :desg, :dess, :desp, :gdes, :gmon, :nbp, :noms, :sour, :term, :tidx, :tiun, :aut
end

class GedHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def encode(text)
    if !text.blank?
        return Iconv.conv('UTF-8', 'ISO-8859-1', text)
    end
  end
  
  def harvest(collection_id, diff=false)
    
    row = Collection.find_by_id(collection_id)
    
    begin 
      @logger.info("[ged_harvester] Host" + row.host)
      @logger.info("[ged_harvester] Db Name :" + row.name)
      _start = Time.now()
      
      # Delete cache for the current collection
      if @local_indexer == 'solr'
        @logger.info("[ged_harvester] Cleaning SOLR Harvesting index")
        clean_solr_index(row.id)
      end
      
      @logger.info("[ged_harvester] Deleting LibraryFind content metadatas")
      clean_sql_data(row.id)
      
      @logger.info("[ged_harvester] Start indexing ...#{row.host}")
      
      flag = true
      n = 1
      documents = Array.new
      File.open(row.host).each do |rec|
        begin
          if flag == true
            flag = false
            # no process for the first raw
            next
          end
          
          dataArray =  Array.new
          i = 0         
          rec.split("\t").each do |element|
            element.chomp!
            dataArray.insert(i,element)
            i+= 1
          end
          
          ged = GedRecord.new
          ged.nuid = dataArray[0]
          ged.dat1 = dataArray[1]
          ged.dat2 = dataArray[2]
          ged.desg = dataArray[3]
          ged.dess = dataArray[4]
          ged.desp = dataArray[5]
          ged.sour = dataArray[6]
          ged.tiun = dataArray[7]
          ged.aut = dataArray[8]
          ged.desg = dataArray[9]
          ged.gdes = dataArray[9]
          ged.gmon = dataArray[10]
          ged.term = dataArray[11]
          ged.tidx = dataArray[12]
          ged.cont = dataArray[13]
          
          dctitle = ""
          dccreator = ""
          dcsubject = ""
          dcdescription = ""
          dcpublisher = ""
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
          
          # title tiun
          dctitle = encode(ged.tiun)
          if dctitle != nil : dctitle = dctitle.gsub('\n', ';') else dctitle = "" end
          
          if ged.desg == nil 
            ged.desg = ""
          end
          
          if ged.dess == nil 
            ged.dess = ""
          end
          
          if ged.desp == nil 
            ged.desp = ""
          end
          
          dcdate = to_date(ged.dat2)
          
          if !ged.cont.nil? : dcdescription = encode(ged.cont) end
          
          dcsubject = encode("#{ged.desg} #{ged.dess} #{ged.desp} #{ged.aut} #{ged.gmon} #{ged.tidx} #{ged.term} #{ged.gdes}".gsub('\n',';'))
          
          if ged.sour != nil: dcpublisher = ged.sour end
          
          
          if ged.nuid != nil: dcidentifier = ged.nuid end
          
          dctype = DocumentType.save_document_type(row.mat_type,row.id)
          
          keyword = "#{dcsubject} #{dcdescription} #{dcpublisher} #{dctype}"
          
          dcsource = row.alt_name
          
          ctitle = dcpublisher + " : " + dctitle
          
          _control = Control.new(
                                 :oai_identifier => dcidentifier, 
                                 :title => ctitle, 
                                 :collection_id => row.id, 
                                 :description => dcdescription, 
                                 :url => row.url, 
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
          
          _stopTimeBase = Time.now()
          main_id = _metadata.id
          _idD = "#{dcidentifier};#{row['id']}"
          
          if @local_indexer == 'solr'
            document_date = ""
            if ged.dat1 != nil: 
              document_date = to_date(ged.dat1)
            end
            date_end_new = DocumentType.getDateEndNew(dctype,document_date.to_s,row['id']) unless document_date == ""
            
            if(date_end_new.nil?)
              documents.push({:id => _idD, :collection_id => row['id'], :collection_name => row.name, :controls_id => last_id, :title => dcpublisher ,:subject => dcsubject, :creator => dccreator + " " + dccontributor, :keyword => keyword, :document_type => dctype, :harvesting_date => Time.new})
            else
              documents.push({:id => _idD, :collection_id => row['id'], :collection_name => row.name, :controls_id => last_id, :title => dcpublisher ,:subject => dcsubject, :creator => dccreator + " " + dccontributor, :keyword => keyword, :document_type => dctype, :harvesting_date => Time.new, :date_end_new => date_end_new})
            end
            
            ptitle = ""
            update_notice(_idD, dcpublisher, dccreator, dctype, ptitle, Time.new)
            
            if n%100==0
              # on index tous les 100 docs
              @index.add(documents)
              documents.clear
            end
            
            # on commit tous les 1000 docs
            if n%10000==0
              @logger.info("[GedHarverster] committed 10000 documents")
              commit
            end
            dataArray = nil
            n+= 1
          end
        rescue Exception=>e
          @logger.error("[GedHarverster] error line #{n} => #{e.message}")
          @logger.error("[GedHarverster] stack: => #{e.backtrace.join("\n")}")
          n+= 1
          next
        end
            
      end # End File.open do
      @logger.info("[ged_harvester] Finished indexing : #{n} documents indexed !!!")
      if documents.empty? == false
        @index.add(documents)
      end
      
    rescue => err
      @logger.error(row.host + ": " + err.message.to_s)
    end
    
    Collection.update(row.id, { :harvested => DateTime::now() })
    commit if LIBRARYFIND_INDEXER.downcase == 'solr'
    @logger.info("###### Temps total ged :" + (Time.now() - _start).to_s + " seconds. #######")
  end
      
  :private
  def to_date(string)
    date_value = ""
    if !string.nil?  
      date_match = string.match(/(19\d\d|20\d\d)(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])/)
      if date_match
        date_value =  "#{date_match[1]}-#{date_match[2]}-#{date_match[3]}"
      end
    end
    return date_value
  end
  
end

    
