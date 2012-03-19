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
require 'oai_dc'
require 'time'
class OaiHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def get_client(hostname, proxy=0)
    client = OAI::Client.new hostname, :parser => PARSER_TYPE
    # add logger
    client.set_logger(@logger)
    # set proxy
    if proxy == 1
      yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
      _host = yp['PROXY_HTTP_ADR']
      _port = yp['PROXY_HTTP_PORT']
      if _host.match(/^http:/)
        _host = _host.gsub("http://","")
      end
      @logger.debug("#{hostname} use proxy: #{_host} with port #{_port} ")
      client.proxy(_host, _port)
    end
    return client
  end
  
  def harvest(collection_id, diff=true)  
    isFound = false
    findError = false    
    @logger.info("DATABASE INFO: " + @db[@dbtype]["database"])
    
    row = Collection.find_by_id(collection_id) 
    
    old_host = nil
    old_parent = 0
    
    if old_host != nil
      if old_host == row.host && old_parent == 1
        @logger.info("Already harvested collection: " + row.name + "...skipping")
        Collection.update(row.id, { :harvested => DateTime::now() })
        next
      elsif old_host != row.host 
        old_host = ""
      else
        old_host = nil
      end
    end  
    
    # nb total documents indexed by collection
    nb_total_index = 0
    # array for solr
    documents = Array.new
    # token oai
    resumption_token=-1
    opts = Hash.new()
    begin 
      @logger.info("id: #{row.id} host: #{row.host} name: #{row.name} parent: #{row.is_parent} oai_set: #{row.oai_set}")
      client = get_client(row.host, row.proxy)
      tmphost = row.host.gsub(":", "_")
      @logger.debug("#{row.host} Connected...")
      stop = false
      
      while(!resumption_token.nil? && !stop) do #boucle
          # options for client oai
          ref_dt = DateTime.new(1970,01,01)
          ref_t = Time.parse(ref_dt.to_s)
          if resumption_token == -1
            begin
              if row.is_parent != 1
                opts["set"] = row.oai_set
              end
              opts["metadata_prefix"] = row.record_schema
              if !row.harvested.blank? and diff
                opts["from"] = row.harvested.utc.xmlschema unless row.harvested.nil?
                @logger.info("#{row.host} harvested opts[from]: #{opts["from"]}")
              elsif !row.harvested.blank? and !diff
                opts["from"] = ref_t.utc.xmlschema
                @logger.info("#{row.host} harvested opts[from]: #{opts["from"]}")
              end
              
              @logger.info("#{row.host} start indexing ...")
              @logger.info("#{row.host} opts: #{opts.inspect}")
              records = client.list_records opts
            rescue Exception => e
              @logger.info(" #{row.host} message : #{e.message}")
              if defined?(e.code) and !e.code.nil?
                if e.code == 'noRecordsMatch'
                  #For harvesting materials using a from, if there are no 
                  #records, we get this error code. 
                  @logger.info(" #{row.host} No data to retrieve")
                else
                  if (e.message.match(/date/) or e.message.match(/syntax/) or e.message.match(/from/) or e.message.match(/argument/))
                    @logger.info("#{row.host} Trying other date format")
                    if !row.harvested.blank? and diff
                      opts["from"] = row.harvested.strftime('%Y-%m-%d')
                      @logger.info("#{row.host} Change to #{opts["from"]}")
                    elsif !row.harvested.blank? and !diff
                      opts["from"] = ref_t.strftime('%Y-%m-%d')  
                    end
                  end
                end
              else
                @logger.error("[OAI HARVESTER] #{row.host} : #{e.message}")
                @logger.debug("[OAI HARVESTER] #{row.host} #{e.backtrace.join("\n")}")
              end
              @logger.info("#{row.host} Dropped into rescue mode Name: #{row.host}")
              if opts["from"].nil? and !row.harvested.nil? and diff
                opts["from"] = row.harvested.utc.xmlschema 
              elsif opts["from"].nil? and !row.harvested.nil? and !diff
                opts["from"] = ref_t.utc.xmlschema
              end
              opts["metadata_prefix"] = row.record_schema
              if row.is_parent != 1
                opts["set"] = row.oai_set
              end
              begin
                records = client.list_records opts
              rescue => e
                if e.message.match(/No data for those parameters/)
                  @logger.info("#{row.host} No data to retrieve:  #{e.message}")
                  break
                else
                  @logger.error("[OAI HARVESTER] #{row.host} Error encountered:  #{e.message}")
                  raise e
                end
              end
            end
            # With token
          else
            @logger.debug("#{row.host} Resumption Token for data: #{resumption_token}")
            try_list = true
            has_try = false
            while(try_list)
              begin
                records = client.list_records :resumption_token => resumption_token
                try_list = false
              rescue => e
                @logger.error("[OAI HARVESTER] #{row.host} : Unknown error... Skipping rest of harvest for this site. \n => [code:#{e.class}] \n #{e.message}")
                if !has_try
                  if !defined?(e.code)
                    @logger.warn("[OAI HARVESTER] Error : but retry with message #{e.message}")
                  else
                    @logger.warn("[OAI HARVESTER] Error : but retry with code #{e.code}")
                  end
                  has_try = true
                else
                  resumption_token = nil
                  raise e
                end
              end
            end
          end
          
          # analyse respond without errors
          if !records.nil?
            @logger.debug("#{row.host} listed results: #{records}")
          else
            @logger.info("#{row.host} response is nil")
          end
          
          resumption_token = records.resumption_token
          if resumption_token == '': resumption_token = nil end
          
          x = 0
          oaidc = OaiDc.new()
          for record in records
            set_spec = record.header.set_spec.to_s
            set_spec = set_spec.gsub(/<\/?[^>]*>/, "")
            oaidc.parse_metadata(record)
            if oaidc.title != nil
              prim_title = checknil(oaidc.title[0])
            else
              prim_title = "untitled"
            end
            oai_identifier = record.header.identifier
            @logger.debug("[#{row.name}] oai_identifier = #{oai_identifier}")
            _control = Control.find(:first, :conditions => ["oai_identifier = ? and collection_id = ?", oai_identifier, row.id])
            if _control.nil?
              _control = Control.new()
              isFound = false
            else
              isFound = true
            end
            
            @logger.debug("[#{row.name}] oai_identifier = #{oai_identifier} collection_id = #{row.id} found ? #{isFound}")
            
            collection_id = row.id
            if !oaidc.description.nil?
              prim_description = checknil(oaidc.description[0])
            else
              prim_description = ""
            end
            
            url = ""
            if !oaidc.identifier.nil? and !oaidc.identifier.empty?
              oaidc.identifier.each do |idm|
                if idm.starts_with?("http://")
                  url = idm
                end
              end
            end
            
            _control.oai_identifier = oai_identifier
            _control.title = prim_title
            _control.collection_id = collection_id
            _control.description = prim_description
            _control.url = url
            _control.collection_name = row.name
            _control.save!()
            
            if (_control.id.nil?)
              raise "Error: control id is nil"
            end
            
            last_id = _control.id
            #======================================
            #set harvested values
            #====================================== 
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
            dclanguage = ""
            
            if oaidc.title != nil: dctitle = oaidc.title.join("; ").gsub('; ;',';') end
            if oaidc.creator != nil: dccreator = oaidc.creator.join("; ").gsub('; ;',';') end
            if oaidc.creator!=nil
              oaidc.creator.each {|_tmp|
                if _tmp != nil
                  if _tmp.index(',')!=nil
                    _tmpa = _tmp.split(',')
                    if _tmpa.length >= 2
                      dccreator << _tmpa[1] + ' ' + _tmpa[0] + '; '
                    end
                  end
                end
              }
            end
            if oaidc.subject != nil: dcsubject = oaidc.subject.uniq.join("; ").gsub('; ;',';') end
            if oaidc.description != nil: dcdescription = oaidc.description.join("; ").gsub('; ;',';') end
            if oaidc.publisher != nil: dcpublisher = oaidc.publisher.uniq.join("; ").gsub('; ;',';') end
            if oaidc.contributor != nil: dccontributor = oaidc.contributor.uniq.join("; ").gsub('; ;',';') end
            if oaidc.date != nil: dcdate = oaidc.date.join("; ").gsub('; ;',';') end
            if oaidc.language != nil: dclanguage = oaidc.language.uniq.join("; ").gsub('; ;',';') end
            if oaidc.type != nil: dctype = oaidc.type.uniq.join("; ").gsub('; ;',';') end
            dctype = DocumentType.save_document_type(dctype,row.id)
            if oaidc.format != nil: dcformat = oaidc.format.uniq.join("; ").gsub('; ;',';') end
            if oaidc.identifier != nil: dcidentifier = oaidc.identifier.join("; ").gsub('; ;',';') end
            if oaidc.source != nil: dcsource = oaidc.source.join("; ").gsub('; ;',';') end
            if oaidc.relation != nil: dcrelation = oaidc.relation.uniq.join("; ").gsub('; ;',';') end
            if oaidc.coverage != nil: dccoverage = oaidc.coverage.uniq.join("; ").gsub('; ;',';') end
            if oaidc.rights != nil: dcrights = oaidc.rights.uniq.join("; ").gsub('; ;',';') end
            keyword = dctitle + " " + dccreator + " " + dcsubject + " " + dcdescription + " " + dcpublisher + " " + dccontributor + " " + dccoverage + " " + dcrelation + " " + dctype
            if oaidc.thumbnail != nil: dcthumbnail = oaidc.thumbnail.join("") end
            
            #========================================================================
            # If thumbnail is blank and the item is set an an image, then we 
            # assume that its a CONTENTdm resource (for now) and build a link to the
            # CDM image.
            #========================================================================
            if row['mat_type'].downcase == 'image' && dcthumbnail == ''
              #build the CDM image location
              thumbstem = url.split('u?')[0]
              thumbargs = url.split('u?/')[1]
              if thumbargs!=nil and thumbargs!=''
                thumbarg_parts = thumbargs.split(',')
                dcthumbnail = thumbstem + 'cgi-bin/thumbnail.exe?CISOROOT=/' + thumbarg_parts[0] +'&CISOPTR=' + thumbarg_parts[1]
              end
            end
            
            if dcrelation.match(/^http:\/\/.*[jpg|png|bmp]$/) and !dcrelation.nil?
              dcthumbnail = dcrelation
            end
            
            
            _metadata = Metadata.find(:first, :conditions => ["controls_id = ?", last_id])
            
            if _metadata.nil?
              _metadata = Metadata.new()
              isFound = false
            else
              isFound = true
            end
            
            _metadata.controls_id = last_id
            _metadata.collection_id = row.id
            _metadata.dc_title = dctitle
            _metadata.dc_creator = dccreator
            _metadata.dc_subject = dcsubject
            _metadata.dc_description = dcdescription
            _metadata.dc_publisher = dcpublisher
            _metadata.dc_contributor = dccontributor
            _metadata.dc_date = dcdate
            _metadata.dc_type = dctype
            _metadata.dc_format = dcformat
            _metadata.dc_identifier = oai_identifier
            _metadata.dc_source = dcsource
            _metadata.dc_relation = dcrelation
            _metadata.dc_coverage = dccoverage
            _metadata.dc_rights = dcrights
            _metadata.dc_language = dclanguage
            _metadata.osu_thumbnail = dcthumbnail
            
            _metadata.save!()
            
            # Saving the document_type
            type = DocumentType.save_document_type(dctype,row.id)  
            document_type = PrimaryDocumentType.getNameByDocumentType(type, row.id)
            main_id = _metadata.id
            
            _idD = "#{oai_identifier};#{row['id']}"
            
            if @local_indexer == 'ferret'
              if isFound == true
                doc = @index[main_id.to_s]
                doc[:collection_id] = row['id']
                doc[:collection_name] = row.name
                doc[:controls_id] = last_id
                doc[:title] = dctitle
                doc[:subject] = dcsubject
                doc[:author] = dccreator + " " + dccontributor
                doc[:keyword] = keyword
                @index << doc
              else  
                @index << {:id => _idD, :collection_id => row['id'], :collection_name => row.name, :controls_id => last_id, :title => dctitle, :subject => dcsubject, :creator => dccreator + " " + dccontributor, :keyword => keyword}
              end
              
            elsif @local_indexer == 'solr'
              documents.push({:id => _idD, :collection_id => row['id'], :collection_name => row.name, :controls_id => last_id, :title => dctitle, :subject => dcsubject, :creator => dccreator + " " + dccontributor, :keyword => keyword, :document_type => document_type, :harvesting_date => Time.new})
              isbn = ""
              notes_count = 0
              notes_avg = 0.0
              ptitle = nil
              update_notice(_idD, dctitle, dccreator, dctype, ptitle, Time.new)
              if nb_total_index > 0 and nb_total_index%100==0
              # on index tous les 100 docs
                @index.add(documents)
                documents.clear
              end
              
              # on commit tous les 10000 docs
              if nb_total_index > 0 and nb_total_index%10000==0
              @logger.info("[OAI HARVESTER] committed 10000 documents to solr")
              commit
            end
            
          end
            
          x += 1
          nb_total_index += 1
         end # end for records   
         @logger.debug("#{row.host} #{x} documents added to index")
                
              end # until resumption_token == nil #fin boucle
              
            rescue => err
              if err.message.match(/No data for those parameters/)
                @logger.info("#{row.host}: No data => #{err.message}.")
              else
                @logger.error("[OAI HARVESTER] #{row.host} Error #{err.message}.")
                @logger.error("[OAI HARVESTER] #{row.host} [class : #{err.class}] Trace: \n#{err.backtrace}.")
                findError = true
              end
            end
            
            if documents.empty? == false
              @index.add(documents)
              documents.clear
            end
            
            @logger.info("#{row.name} total: #{nb_total_index} documents harvested")
            if !findError and nb_total_index > 0
              Collection.update(row.id, { :harvested => DateTime::now() })
            end
            
            if row.is_parent.to_s == '1'
              @logger.info("is parent set")
              old_host = row.host
              old_parent = 1 
            elsif old_host == row.host && old_parent == 1
              old_host = row.host
              old_parent = 1
            else
              old_host = row.host
              old_parent = 0
            end 
            
            if LIBRARYFIND_INDEXER.downcase == 'solr'
              @logger.debug("[OAI HARVESTER] COMMIT_FINAL")
              commit
            end
            
            if LIBRARYFIND_INDEXER.downcase == 'ferret'
              @index.close()
            end
            
          end
        end
