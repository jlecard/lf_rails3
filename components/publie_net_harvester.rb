require 'common_harvester'
require 'publie_net'
require 'marc'

class PublieNetHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def to_utf8(string)
    if !string.blank?
        return Iconv.conv('UTF-8', 'ISO-8859-1', string)
    end
  end
  
  def harvest(collection_id=nil,diff=true)
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
    
    download_dir = "#{RAILS_ROOT}/components/publie_net"
    #@logger.debug("[PublieNetHarvester][Harvest] download_dir =  #{download_dir}")
    PublieNet.download_marc_files(download_dir, _host, _port, @logger)
    readers = PublieNet.read_marc_files(download_dir, @logger)
    if !readers.nil?
      begin
        readers.each do |reader|
          if !reader.nil?
            tags = ['001','010','073','100','101','102','106','200','210',
                    '215','225','230','305','310','610','700','801','856']

            for rec in reader
              dcidentifier = ""
              dcnumISBN13 = ""
              dcprice = ""
              dcnumEAN13 = ""
              dclang = ""
              dctitle = ""
              dcdescription = ""
              dcauthor = ""
              dcsource = ""
              dcyear = ""
              dcpublisher = ""
              dcformat = Array.new
              dcdispo = ""
              dcsubject = Array.new
              dcauthorfamilyname = ""
              dcauthorfirstname = ""
              dcdirectUrl = ""
              
              
              fields = rec.find_all { | field | tags.include?(field.tag) }
              fields.each do |field|
                case field.tag
                  when '001'
                  dcidentifier = field.value
                  when '010'
                  field.subfields.each do |subfield|
                    case subfield.code 
                      when "a"
                        dcnumISBN13 = subfield.value
                      when "d"
                        dcprice = subfield.value
                    end
                  end
                  when '073'
                  field.subfields.each do |subfield|
                    case subfield.code 
                      when "a"
                        dcnumEAN13 = subfield.value
                    end
                  end
                  when '102'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dclang = subfield.value
                    end
                  end
                  when '200'
                  field.subfields.each do |subfield|
                    case subfield.code 
                      when "a"
                        dctitle = subfield.value
                      when "e"
                        dcdescription = subfield.value
                      when "f"
                        dcauthor =  subfield.value
                    end
                  end
                  when '210'
                  field.subfields.each do |subfield|
                    case subfield.code 
                      when "c"
                        dcsource = subfield.value
                      when "d"
                        dcyear =  subfield.value
                    end
                  end
                  when '225'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dcpublisher = subfield.value 
                    end
                  end
                  when '230'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dcformat.push(subfield.value) 
                    end
                  end
                  when '310'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dcdispo = subfield.value 
                    end
                  end
                  when '610'
                  field.subfields.each do |subfield|
                    if subfield.code == "a"
                      dcsubject.push(subfield.value)
                    end
                  end
                  when '700'
                  field.subfields.each do |subfield|
                    case subfield.code 
                      when "a"
                        dcfamilyname = subfield.value
                      when "b"
                        dcfirstname =  subfield.value
                    end
                  end
                  when '856'
                  field.subfields.each do |subfield|
                    if subfield.code == "u"
                      dcdirectUrl = subfield.value 
                    end
                  end   
                end
              end
              
              
              dcformat = dcformat.join(";")
              dcsubject = dcsubject.join(";")
              osulinking = dcdirectUrl
              dcdate = dcyear
              

              dctype = ""
              dcrights = ""
              dcthumbnail = ""
              keyword = ""
              dcvolume = ""
              dcsubject = ""
              dccontributor = ""
              dcrelation = ""
              dccoverage = ""
              
              keyword = "#{dctitle} #{dcdescription} #{dcpublisher} #{dctype}"
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
                                         :dc_creator => dcauthor, 
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
                  @index << {:id => _idD, :collection_id => row.id, :collection_name => row.name, :controls_id => last_id, :title => dcpublisher, :subject => dcsubject, :creator => dcauthor + " " + dccontributor, :keyword => keyword, :publisher => dcpublisher}           
                elsif @local_indexer == 'solr'
                  documents.push({:id => _idD, :collection_id => row.id, :collection_name => row.name, :controls_id => last_id, :title => dctitle ,:subject => dcsubject, :creator => dcauthor, :keyword => keyword, :publisher => dcpublisher, :document_type => dctype, :harvesting_date => Time.new})
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
      
      @logger.info("###### Total time on Publie.net :" + (Time.now() - _start).to_s + " seconds. #######")
      
      #close the ferret indexes
      @index.close() if LIBRARYFIND_INDEXER.downcase == 'ferret'
      
    end
    
  end
