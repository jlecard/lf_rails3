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
require 'dbi'
require ENV['LIBRARYFIND_HOME'] + 'app/models/themes_reference'
require ENV['LIBRARYFIND_HOME'] + 'app/models/theme'
require ENV['LIBRARYFIND_HOME'] + 'components/portfolio/portfolio_theme'

class PortfolioHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def normalizePortfolio(word)
    return "" if word == nil
#    word = word.gsub("--", "@;@")
    word = word.gsub("@;@", "|LF_DEL|")
    word = word.gsub(";", ",")
    word = word.gsub(", , ", ", ")
    word = word.gsub("/ , ", ", ")
    word = word.gsub("|LF_DEL|", ";")
    word = word.chomp(",")
    word = word.chomp("/;")
    word = word.chomp(";")
    word = word.chomp("/")
    return word
  end
  
  def normalizeTitle(word)
    word = normalizePortfolio(word)
    word = word.gsub(" : ; ", ": ")
    word = word.gsub(" : / ", ": ")
    word = word.gsub(" / : ", ": ")
    word = word.gsub(" / ; ", "; ")
    word = word.gsub(" = ; ", "; ")
    word = word.chomp(",")
    word = word.chomp("/;")
    word = word.chomp(";")
    word = word.chomp("/")
    return word
  end
  
  def sanitize_sql(string)
    if string.nil?
      string = ""
    end
    ActiveRecord::Base.send(:sanitize_sql_for_conditions, ['?', string])
  end
  
  def harvest(collection_id, diff = true)
    total_time_start = Time.now
    @logger.info("[portfolio_harvester] DATABASE INFO: " + @db[@dbtype]["database"])
    begin
      row = Collection.find_by_id(collection_id)
      query = "";
      ids = Array.new
      @logger.info("Host : #{row.host}")
      @logger.info("ID: #{row.id} Db name: #{row.name}")
      last_harvest = row.harvested
      logger.info("[portfolio_harvester] LASTHARVEST IS #{last_harvest.class}")
      logger.info("[portfolio_harvester] LASTHARVEST : #{last_harvest}")
      logger.info("[portfolio_harvester] LASTHARVEST UTC : #{last_harvest.utc}")
      _uri = "DBI:Pg:database=#{row.name};host=#{row.host}"
      if diff
        @conn = DBI.connect(_uri, row.user, row.pass)
        @logger.info("[portfolio_harvester] Connection done to #{row.host} using #{row.name}")
        #diff - get modified ids
        query = "SELECT dc_identifier FROM dc_notices_flags where time > '#{last_harvest.utc}'" 
        _query = @conn.prepare(query)
        _query.execute
        _query.fetch do |updated_rows|
          ids.push(updated_rows['dc_identifier'])
        end
        _query.finish
        @logger.info("[portfolio_harvester] FOUND #{ids.size} modified rows")
        if ids.size > 100000
          ids.clear
          @logger.info("[portfolio_harvester] more than 100000 modified records... Launching full harvest")
          diff = false
        elsif ids.size == 0
          @logger.info("[portfolio_harvester] No changed records... Skipping")
          @conn.disconnect
          return
        end
      end
      #Delete cache for the current collection
      @logger.info("[portfolio_harvester] Cleaning SOLR Harvesting")
      clean_solr_index(collection_id, ids)
      
      # Clear MySql data tables
      clean_sql_data(collection_id, ids)
      # Portfolio specific
      clean_query = "delete from portfolio_datas" 
      clean_query += " where dc_identifier in (#{ids.join(" ,")})" if !ids.empty?
      ActiveRecord::Base.connection.execute(clean_query)
      
    
      _themePortfolio = PortfolioTheme.new(@conn, @logger, row.name)
       
      nb_results = 0
      query = "SELECT count(*) as nb FROM dc_notices"
      query += " where dc_identifier in (#{ids.join(",")})" if !ids.empty?
      r = @conn.select_one(query)
      nb_results = r['nb'].to_i
      @logger.info("[portfolio_harvester] Ready to index #{nb_results} records.")

      i = 0
      documents = Array.new
      nbError=0
      
      query_start = Time.now
      query = "SELECT * FROM dc_notices"
      query += " where dc_identifier in (#{ids.join(",")})" if !ids.empty?
      _query = @conn.prepare(query)
      _query.execute
      query_end = Time.now
      query_time = query_end - query_start
      @logger.info("POSTGRES QUERY DURATION = #{query_time} s")
      @logger.debug("[portfolio_harvester] Started Indexing in #{LIBRARYFIND_SOLR_HARVESTING_URL}")
      
      metadata_inserts = Array.new
      control_inserts = Array.new
      portfolio_data_inserts = Array.new
      volume_inserts = Array.new
      _query.fetch do |portRow|
        begin
          start_time = Time.now
          if portRow.nil?
            raise 'Row Nil'
          end
          
          ## Indexing data in the search engine
          title = normalizeTitle(portRow['dc_title'])
          creator = normalizePortfolio(portRow['dc_creator'])
          subject = normalizePortfolio(portRow['dc_subject'])
          description = normalizePortfolio(portRow['dc_description'])
          publisher = normalizePortfolio(portRow['dc_publisher'])
          language = normalizePortfolio(portRow['dc_language_long'])
          theme = normalizePortfolio(portRow['bpi_theme_lib'])
          if !portRow['bpi_indice'].blank? and theme.blank?
            theme = _themePortfolio.translateTheme(portRow['bpi_indice'])
            logger.debug("THEME = #{theme}")
          end
          indice = normalizePortfolio(portRow['bpi_indice'])
          last_issue = portRow['bpi_dernier_no']
          issues = portRow['bpi_collection']
          binding = portRow['bpi_reliure']
          logger.debug("[PortfolioHarvester] themes : #{theme}")
          identifier = portRow['dc_identifier']
          custom_document_type = portRow['dc_type']
          type = DocumentType.save_document_type(portRow['dc_type'], row.id)
          type = PrimaryDocumentType.getNameByDocumentType(type, row.id)
          
          issn = normalizePortfolio(portRow['bpi_issn'])
          isbn = normalizePortfolio(portRow['bpi_isbn'])
          contributor = normalizePortfolio(portRow['dc_contributor'])
          if !contributor.blank?
            contributor += ";#{normalizePortfolio(portRow['bpi_creator2'])}"
          else
            contributor = "#{normalizePortfolio(portRow['bpi_creator2'])}"
          end
          keyword = normalizePortfolio(title + " " + creator + " " + contributor + " " + subject + " " + description + " " + publisher + " " + theme + " " + type) 
          dcdate = portRow['dc_date_long']
          dcformat = normalizePortfolio(portRow['dc_format'])
          relation = normalizePortfolio(portRow['dc_relation'])
          coverage = normalizePortfolio(portRow['dc_coverage'])
          if !portRow['bpi_copy'].blank? 
            dcrights = "#{portRow['bpi_copy']}.\n #{portRow['dc_rights']}"
          else
            dcrights = portRow['dc_rights']
          end 
          issue_title = portRow['dc_title_revue']
          conservation = portRow['bpi_conservation'] 
          # Saving the document_type
          DocumentType.save_document_type(type,row['id'])
          
          # Saving date_end_new
          document_date = nil
          if !portRow['bpi_nouveaute'].blank?
            document_date = portRow['bpi_nouveaute']
          end
          # nouveauté si disponible
          date_end_new = nil
          if !portRow['bpi_dispo'].blank? and portRow['bpi_dispo'].starts_with?("D")
            date_end_new = DocumentType.getDateEndNew(type,document_date,row['id'])
          end
          
          # bpi_loca : cote
          if !portRow['bpi_cote'].blank?
            cote = portRow['bpi_cote'].split(" @;@ ")
            ind = 0
            cote.each do |c|
              cote[ind] = c.strip
              ind += 1
            end
          end
          
          # retrieve bdm, iddoc, idweb, idomm...
          bdm_info = Array.new
          vol_title = portRow['bpi_dm_title'].split(" @;@ ") unless portRow['bpi_dm_title'].blank?
          barcode_field = ""
          if !portRow['bpi_dm_launch'].blank?
            string = portRow['bpi_dm_launch']
            str_array = string.split(" @;@ ")
            idx = 0
            str_array.each do |str|
              bdm, iddoc, idomm = ""
              match = str.match(/http:\/\/.*\/([a-z]+)\/LaunchOMM\.aspx\?IdDoc=(\d+)&IdOmm=(\d+)/)
              if !match.nil?
                bdm = match[1] if !match[1].nil? 
                iddoc = match[2] if !match[2].nil?
                idomm = match[3] if !match[3].nil?
              end
              idweb = nil
              match = nil
              if str.match(/IdWeb/)
                match = str.match(/IdWeb=(\d+)/)
                idweb = match[1]
              end
              doc_title = ""
              if !vol_title.nil? and !vol_title[idx].nil?
                doc_title = vol_title[idx]
              end
              barcode = ""
              barcode = portRow['bpi_dm_barcode'].split(" @;@ ") unless portRow['bpi_dm_barcode'].blank?
              
              barcode_field = portRow['bpi_dm_barcode'].gsub(" @;@ ", ";") unless portRow['bpi_dm_barcode'].nil?
              if !barcode.kind_of?(String) and !barcode.nil?
                if !barcode[idx].nil? 
                  barcode = barcode[idx] 
                end
              end
              bdm_tmp = "bdm=#{bdm}|iddoc=#{iddoc}|idomm=#{idomm}|doc_title=#{doc_title}|barcode=#{barcode}"
              if !idweb.nil?
                bdm_tmp = "#{bdm_tmp}|idweb=#{idweb}" 
              end
              bdm_info.push(bdm_tmp)
              bdm_tmp = "" # reset temporary string
              idx += 1
            end 
          end
          
          # Create control statements
          control_statement = "(#{sanitize_sql(identifier)},#{sanitize_sql(title)},#{sanitize_sql(collection_id)}, #{sanitize_sql(description)}, #{sanitize_sql(row.name)})"
          control_inserts.push(control_statement)
          
          # Create metadata statement
          metadata_statement = "(#{row.id},#{sanitize_sql(title)},#{sanitize_sql(creator)}
                      ,#{sanitize_sql(subject)}, #{sanitize_sql(description)}, #{sanitize_sql(publisher)}
                      ,#{sanitize_sql(contributor)},#{sanitize_sql(dcdate)},#{sanitize_sql(type)}
                      ,#{sanitize_sql(dcformat)},#{sanitize_sql(identifier)},#{sanitize_sql(relation)}
                      ,#{sanitize_sql(coverage)},#{sanitize_sql(dcrights)},#{sanitize_sql(language)})"
          metadata_inserts.push(metadata_statement)

          # Create portfolio_data statement
          if !portRow['bpi_dispo'].blank? and portRow['bpi_dispo'].starts_with?("D")
            portfolio_data_available = 1
          else
            portfolio_data_available = 0
          end
          
          if !portRow['bpi_gr_diff'].blank?
            broadcast_groups = portRow['bpi_gr_diff'].gsub(/ @;@ /,";")
            @logger.debug("[PortfolioHarvester][harvest] broadcast_groups = #{broadcast_groups}")
          end
          portfolio_data_statement = "(#{sanitize_sql(identifier)},#{sanitize_sql(portRow['bpi_audience'])},#{sanitize_sql(portRow['bpi_genre'])},
                                         #{sanitize_sql(last_issue)}, #{sanitize_sql(issn)}, #{sanitize_sql(isbn)},
                                         #{sanitize_sql(theme)},#{portfolio_data_available}, #{sanitize_sql(indice)}, 
                                         #{sanitize_sql(broadcast_groups)},#{sanitize_sql(issues)},#{sanitize_sql(binding)},
                                         #{sanitize_sql(issue_title)}, #{sanitize_sql(conservation)})"
          portfolio_data_inserts.push(portfolio_data_statement)
          
          # Create volume statements
          volume_barcode = ""
          volume_doc_id = ""
          volume_object_id = ""
          volume_source = ""
          call_num = portRow['bpi_cote'].split(" @;@ ") unless portRow['bpi_cote'].blank? 
          location = portRow['bpi_loca'].split(" @;@ ") unless portRow['bpi_loca'].blank? 
          label = portRow['bpi_dm_lien_lib'].split(" @;@ ") unless portRow['bpi_dm_lien_lib'].blank?
          launch_url = portRow['bpi_dm_launch'].split(" @;@ ") unless portRow['bpi_dm_launch'].blank?
          support = portRow['dc_format_court'].split(" @;@ ") unless portRow['dc_format_court'].blank?
          resource_link = portRow['bpi_dm_lien_url'].split(" @;@ ") unless portRow['bpi_dm_lien_url'].blank?
          idx = 0
          if !portRow['bpi_dispo_ex'].blank? and (!portRow['bpi_dm_launch'].match(/IdOmm.*@;@/) or !portRow['bpi_dm_launch'].match(/.*@;@.*IdOmm/)) 
            portRow['bpi_dispo_ex'].split(" @;@ ").each do |volume|
              volume_call_num = call_num[idx].to_s.strip unless call_num.nil? or call_num[idx].nil? 
              volume_record_location = location[idx].to_s.strip unless location.nil? or location[idx].nil?
              if vol_title.blank? or vol_title[idx].blank?
                if label.blank? or label[idx].blank?
                  volume_label = "#{title}"
                else
                  volume_label = label[idx] unless label[idx].blank?
                end
              elsif vol_title.kind_of?(String)
                volume_label = "#{title}"
              else
                volume_label = vol_title[idx]
              end
             
              volume_barcode = ""
              volume_doc_id = ""
              volume_object_id = ""
              volume_source = ""
              volume_link = resource_link[idx].strip unless resource_link.nil? or resource_link[idx].nil?
              volume_launch_url = launch_url[idx].strip unless launch_url.nil? or launch_url[idx].nil?
              volume_support = support[idx].to_s.strip unless support.nil? or support[idx].nil?
              volume_number = idx+1
              if !bdm_info.nil? and !bdm_info[idx].nil?
                volume_barcode = bdm_info[idx].match(/barcode=(\d+)/)[1] if bdm_info[idx].match(/barcode=(\d+)/)
                volume_doc_id = bdm_info[idx].match(/iddoc=(\d+)/)[1] if bdm_info[idx].match(/iddoc=(\d+)/)
                volume_object_id = bdm_info[idx].match(/idomm=(\d+)/)[1] if bdm_info[idx].match(/idomm=(\d+)/) 
                volume_source = bdm_info[idx].match(/bdm=([a-z]+)|/i)[1] if bdm_info[idx].match(/bdm=([a-z]+)|/i)
              end
              volume_statement = "(#{sanitize_sql(identifier)}, #{row.id}, #{sanitize_sql(volume.strip)},#{sanitize_sql(volume_call_num)}
                                     ,#{sanitize_sql(volume_record_location)}, #{sanitize_sql(volume_label)}, #{sanitize_sql(volume_link)}
                                     ,#{sanitize_sql(volume_launch_url)}, #{sanitize_sql(volume_support)},#{sanitize_sql(volume_number)}
                                    ,#{sanitize_sql(volume_barcode)},#{sanitize_sql(volume_doc_id)},#{sanitize_sql(volume_object_id)}
                                    ,#{sanitize_sql(volume_source)} )"
              volume_inserts.push(volume_statement)
              idx += 1
            end
          elsif !portRow['bpi_cote'].blank? and (!portRow['bpi_dm_launch'].match(/IdOmm.*@;@/) or !portRow['bpi_dm_launch'].match(/.*@;@.*IdOmm/))
            portRow['bpi_cote'].split(" @;@ ").each do |cote|
              volume_call_num = cote 
              volume_record_location = location[idx].to_s.strip unless location.nil? or location[idx].nil?
              if vol_title.blank? or vol_title[idx].blank?
                if label.blank? or label[idx].blank?
                  volume_label = "#{title}"
                else
                  volume_label = label[idx] unless label[idx].blank?
                end
              elsif vol_title.kind_of?(String)
                volume_label = "#{title}"
              else
                volume_label = vol_title[idx]
              end
              volume_link = resource_link[idx].strip unless resource_link.nil? or resource_link[idx].nil?
              volume_launch_url = launch_url[idx].strip unless launch_url.nil? or launch_url[idx].nil?
              volume_support = support[idx].to_s.strip unless support.nil? or support[idx].nil?
              volume_number = idx+1
              volume_statement = "(#{sanitize_sql(identifier)}, #{row.id}, 'Disponible',#{sanitize_sql(volume_call_num)}
                                     ,#{sanitize_sql(volume_record_location)}, #{sanitize_sql(volume_label)}, #{sanitize_sql(volume_link)}
                                     ,#{sanitize_sql(volume_launch_url)}, #{sanitize_sql(volume_support)},#{sanitize_sql(volume_number)}
                                     ,'','','','' )"
              volume_inserts.push(volume_statement)
              idx += 1
            end
          elsif portRow['bpi_dm_launch'].match(/IdOmm.*@;@/) or portRow['bpi_dm_launch'].match(/.*@;@.*IdOmm/)
            portRow['bpi_dm_launch'].split(" @;@ ").each do |webobj|
              volume_call_num = call_num[idx].to_s.strip unless call_num.nil? or call_num[idx].nil? 
              volume_record_location = location[idx].to_s.strip unless location.nil? or location[idx].nil?
              if !label.blank? and label.kind_of?(Array)
                  lab = label[idx]
                  if !lab.nil? and lab.length > 50  
                    lab = "#{lab[0..49]}..."
                  end
                  volume_label = label[idx]
              elsif vol_title.kind_of?(String) or vol_title[idx].nil?
                volume_label = "#{title}"
              else
                volume_label = vol_title[idx]
              end
              volume_barcode = ""
              volume_doc_id = ""
              volume_object_id = ""
              volume_source = ""
              volume_link = resource_link[idx].strip unless resource_link.nil? or resource_link[idx].nil?
              volume_launch_url = launch_url[idx].strip unless launch_url.nil? or launch_url[idx].nil?
              volume_support = support[idx].to_s.strip unless support.nil? or support[idx].nil?
              volume_number = idx+1
              if !bdm_info.nil? and !bdm_info[idx].nil?
                volume_barcode = bdm_info[idx].match(/barcode=(\d+)/)[1] if bdm_info[idx].match(/barcode=(\d+)/)
                volume_doc_id = bdm_info[idx].match(/iddoc=(\d+)/)[1] if bdm_info[idx].match(/iddoc=(\d+)/)
                volume_object_id = bdm_info[idx].match(/idomm=(\d+)/)[1] if bdm_info[idx].match(/idomm=(\d+)/) 
                volume_source = bdm_info[idx].match(/bdm=([a-z]+)|/i)[1] if bdm_info[idx].match(/bdm=([a-z]+)|/i)
              end
              volume_statement = "(#{sanitize_sql(identifier)}, #{row.id}, 'Consultable sur ce poste',#{sanitize_sql(volume_call_num)}
                                     ,#{sanitize_sql(volume_record_location)}, #{sanitize_sql(volume_label)}, #{sanitize_sql(volume_link)}
                                     ,#{sanitize_sql(volume_launch_url)}, #{sanitize_sql(volume_support)},#{sanitize_sql(volume_number)}
                                    ,#{sanitize_sql(volume_barcode)},#{sanitize_sql(volume_doc_id)},#{sanitize_sql(volume_object_id)}
                                    ,#{sanitize_sql(volume_source)} )"
              volume_inserts.push(volume_statement)
              idx += 1
            end  
          end
          
          # date for rss feed
          if (!document_date.blank?)
            harvesting_date = Date.parse(document_date)
            harvesting_date = harvesting_date.to_s + "T23:59:59Z"
          else
            harvesting_date = Time.now()
          end

          # Save in SOLR
          _idD = "#{identifier};#{row['id']}"
          if (date_end_new.nil?)
            documents.push(:id => _idD, :collection_id => row['id'], :controls_id => identifier, :collection_name => row.name, 
                :title => "#{title} #{relation}" ,:creator => "#{creator}; #{normalizePortfolio(portRow['bpi_creator2'])}", :subject => subject, :description => description, :publisher => publisher, 
                :keyword => keyword, :theme => theme, :theme_rebond => theme, :document_type => type, :harvesting_date => harvesting_date, 
                :isbn => isbn, :issn => issn, :cote_rebond => cote, :bdm_info => bdm_info,
                :autocomplete => keyword, :autocomplete_creator => "#{creator}; #{normalizePortfolio(portRow['bpi_creator2'])}", :autocomplete_publisher => publisher, :autocomplete_theme => theme,
                :autocomplete_title => "#{title} #{relation}", :autocomplete_subject => subject, :autocomplete_description => description, :barcode=>barcode_field,
                :indice=>indice, :custom_document_type => custom_document_type)
          else
            documents.push(:id => _idD, :collection_id => row['id'], :controls_id => identifier, :collection_name => row.name,
                :title => "#{title} #{relation}" ,:creator => "#{creator}; #{normalizePortfolio(portRow['bpi_creator2'])}", :subject => subject, :description => description, :publisher => publisher, 
                :keyword => keyword, :theme => theme, :theme_rebond => theme, :document_type => type, :harvesting_date => harvesting_date, 
                :isbn => isbn, :issn => issn, :cote_rebond => cote, :bdm_info => bdm_info, :date_end_new => date_end_new,
                :autocomplete => keyword, :autocomplete_creator => "#{creator}; #{normalizePortfolio(portRow['bpi_creator2'])}", :autocomplete_publisher => publisher, :autocomplete_theme => theme,
                :autocomplete_title => "#{title} #{relation}", :autocomplete_subject => subject, :autocomplete_description => description,:barcode=>barcode_field,
                :indice=>indice, :custom_document_type => custom_document_type)
          end

          ptitle = ""
          update_notice(_idD, title, creator, type, ptitle, Time.new)
          
          
          
          # Indexing in SOLR 
          if (i > 0 and i % 100 == 0)
            @index.add(documents)
            documents.clear
          end
          
          # Commit to mysql every 1000 docs
          if (i > 0 and i % 1000 == 0)
            insert(metadata_inserts, control_inserts, portfolio_data_inserts, volume_inserts)
          end
          
          # Commit in SOLR every 10000 documents
          if (i > 0 and i % 10000 == 0)
            @logger.info("10000 records ==> ** Committing...")
            commit_start_time = Time.now
            commit
            commit_end_time = Time.now
            commit_duration = commit_end_time - commit_start_time
            @logger.info("10000 records ==> ** Commit Duration : #{commit_duration}")
          end
          
        rescue Exception => e
          nbError+=1
          @logger.error("[portfolio_harvester] #{e.message}")
          @logger.error("[portfolio_harvester] Errors while fetching data : #{$!}. Record title: #{title}\n Record identifier: #{identifier}")
          @logger.error("[portfolio_harvester] Trace : #{e.backtrace.join("\n")}")
        end
        
        i+= 1
      end # fin_query.fetch
      
      _query.finish
      @conn['AutoCommit'] = false
      begin
        @conn.do("LOCK dc_notices_flags IN SHARE UPDATE EXCLUSIVE MODE;")
        nb = @conn.do("DELETE FROM dc_notices_flags where status = 'D';")
        @conn.commit
        @logger.info("[portfolio_harvester] removed #{nb} rows from dc_notices_flags")
      rescue Exception => e
        @conn.rollback
        @logger.error("[portfolio_harvester] error removing deleted rows : #{e.message}")
      end
      @conn['AutoCommit'] = true
      @conn.disconnect
      if !documents.empty?
        @index.add(documents)
      end
      
      @logger.info("[portfolio_harvester] Finished Indexing : #{i} document(s) indexed!!!")
      @logger.info("[portfolio_harvester] nb errors: #{nbError}/#{i}")
      
    rescue => err
      @logger.error("[portfolio_harvester] Errors : #{$!}")
      @logger.error("[portfolio_harvester] Errors : #{err.message}")
      @logger.error("[portfolio_harvester] Trace : #{err.backtrace.join("\n")}")
    end
    
    # Execute insert statements
    insert(metadata_inserts, control_inserts, portfolio_data_inserts, volume_inserts)
    # Commit in SOLR
    commit
    # Create relations between tables
    create_relations(row.id)
    # Update harvest date
    Collection.update(row.id, { :harvested => DateTime::now() })
    
    begin
      @logger.info("[portfolio_harvester] Rapport Themes: [Matched: #{_themePortfolio.matched}] [No Matched: #{_themePortfolio.errors}]")
      path = "#{ENV['LIBRARYFIND_HOME']}/log/themes_#{row.name}_not_match_#{Time.now().to_f}.txt"
      is_write = system("echo #{_themePortfolio.indices_no_match.inspect} > #{path}")
      @logger.info("[portfolio_harvester] Rapport Themes: [write_file:#{is_write}] For more details, check file: #{path}")
    rescue Exception => e
      @logger.warn("Error writing #{path} : #{e.message}")
    end
    
    @logger.info("[portfolio_harvester] Finished processing")
    total_time_end = Time.now
    @logger.info("[portfolio_harvester] Process took #{total_time_end - total_time_start} s")
  end
  
  # Insert data arrays into MySql (tables metadatas, controls, portfolio_datas and volumes)
  def insert(metadata_inserts, control_inserts, portfolio_data_inserts, volume_inserts)
    transaction_start = Time.now
    ActiveRecord::Base.transaction do
      begin
        @logger.info("Insert: size : metadata_inserts: #{metadata_inserts.size} control_inserts; #{control_inserts.size}")
        @logger.info("portfolio_data_inserts: #{portfolio_data_inserts.size} volume_inserts: #{volume_inserts.size}")
        ActiveRecord::Base.connection.execute("INSERT INTO controls(oai_identifier, title, collection_id, description, collection_name) 
                                               VALUES #{control_inserts.join(", ")}")
        ActiveRecord::Base.connection.execute("INSERT INTO metadatas(collection_id, dc_title, dc_creator, dc_subject,  
                                              dc_description, dc_publisher, dc_contributor, dc_date, dc_type, dc_format, dc_identifier, 
                                              dc_relation, dc_coverage, dc_rights, dc_language) 
                                              VALUES #{metadata_inserts.join(", ")}")
        ActiveRecord::Base.connection.execute("INSERT INTO portfolio_datas(dc_identifier, audience, genre, last_issue, issn, isbn, theme, 
                                               is_available, indice, broadcast_group, issues, binding, issue_title, conservation) 
                                              VALUES #{portfolio_data_inserts.join(", ")}")    
        
        ActiveRecord::Base.connection.execute("INSERT INTO volumes(dc_identifier, collection_id, availability, call_num, location,
                                              label, link, launch_url, support, number, barcode, document_id, object_id, source) VALUES #{volume_inserts.join(", ")}")
        
        control_inserts.clear
        metadata_inserts.clear
        portfolio_data_inserts.clear
        volume_inserts.clear
      rescue ActiveRecord::Rollback => e
        @logger.error("Transaction has been rolled back => #{e.message}")
      rescue Exception => e
        @logger.error("Error committing documents in MySql => #{e.message}")
        raise e
      end
    end
    transaction_end = Time.now
    @logger.info("Insert transaction total time  => #{transaction_end - transaction_start} seconds.")
  end
  
  # Update MySql to set foreign keys values and relationships  
  def create_relations(collection_id)
    # Update relations
    ActiveRecord::Base.transaction do
      begin
        update_start = Time.now
        update_sql = "UPDATE metadatas M set M.controls_id = (select C.id from controls C where C.collection_id = #{collection_id} AND M.collection_id = #{collection_id} AND C.oai_identifier = M.dc_identifier)
                            WHERE M.collection_id=#{collection_id}"
        ActiveRecord::Base.connection.execute(update_sql)
        update_sql = "UPDATE volumes V set V.metadata_id = (select M.id from metadatas M where M.collection_id = #{collection_id} AND M.dc_identifier = V.dc_identifier)"
        ActiveRecord::Base.connection.execute(update_sql)
        update_sql = "UPDATE portfolio_datas P set P.metadata_id = (select M.id from metadatas M where M.collection_id = #{collection_id} and M.dc_identifier = P.dc_identifier)"
        ActiveRecord::Base.connection.execute(update_sql)
        update_end = Time.now
        @logger.info("[PortfolioHarverster][Update SQL] Updates done in #{update_end - update_start} ms")
      rescue ActiveRecord::Rollback => e
        @logger.error("Update transaction has been rolled back => #{e.message}")
      rescue Exception => e
        @logger.error("Error updating relations in MySql => #{e.message}")
        raise e
      end
    end
  end
  
  
  # Method checkCollectionRecordsAvailability
  #   params :
  #     collection_id : Integer (collection to check)
  #     docs_identifiers : Array of doc_identifier (Srting)
  #   description :
  #     This method makes connection to collection (in postgres database)
  #       checks for each doc in docs if it's available
  #   returns :
  #     An array of docs available
  def checkCollectionRecordsAvailability(doc_collection_id, docs)
    docs_available = []
    @logger.info("[portfolio_harvester] DATABASE INFO: " + @db[@dbtype]["database"])
    row = Collection.find_by_id(doc_collection_id)
    begin
      docs_ids = docs.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      query = "select dc_identifier from volumes where (dc_identifier IN #{docs_ids}) AND collection_id = #{row.id} AND availability = 'Disponible'"
      result = Volume.find_by_sql(query)
      result.each do |volume|
        begin
          if !volume.nil?
            docs_available << volume.dc_identifier
          end
        rescue => e
          @logger.error("[portfolio_harvester] Errors while fetching data")
          @logger.error("[portfolio_harvester] Trace : #{e.backtrace.join("\n")}")
        end
      end
      return docs_available
    rescue => err
      @logger.error("[portfolio_harvester] Errors : #{err.message}")
      @logger.error("[portfolio_harvester] Trace : #{err.backtrace.join("\n")}")
    end
  end
  
end
