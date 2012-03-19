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

RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)

if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'

class Control < ActiveRecord::Base
end

class Collection < ActiveRecord::Base
end

class Metadata < ActiveRecord::Base
end

class CommonHarvester
  require 'rubygems'
  require 'yaml'
  require 'iconv'
  attr_accessor :logger
  
  def checknil(s)
    if s.nil? : return "" end
    return s
  end
  
  # Constructor method - initialize variables
  def initialize(type=nil)

    @logger = ActiveRecord::Base.logger
    
    @local_indexer = ""
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      require 'ferret'
      include Ferret
      @local_indexer = 'ferret'
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      require 'solr'
      @local_indexer = 'solr'
    end 
    
    @db = YAML::load_file(ENV['LIBRARYFIND_HOME'] + "config/database.yml")
    
    if type.nil?
      @dbtype = 'development'
    else
      @dbtype = type
    end
    
    @reharvest = true
    
    case PARSER_TYPE
      when 'libxml'
      require 'xml/libxml'
      when 'rexml'
      require 'rexml/document'
	  when 'nokogiri'
	  require 'nokogiri'
    else
      require 'rexml/document'
    end
    
    if @local_indexer == 'ferret'
      @index = Index::Index.new(:path => LIBRARYFIND_FERRET_PATH, :create_if_missing => true)
    elsif @local_indexer == 'solr'
      @logger.debug("Timeout set to : #{CFG_LF_TIMEOUT_SOLR}")
      @index = Solr::Connection.new(LIBRARYFIND_SOLR_HARVESTING_URL, {:timeout => CFG_LF_TIMEOUT_SOLR})
    end
    
    
    if @local_indexer == 'ferret'
      @logger.debug("FERRET INDEX: " + LIBRARYFIND_FERRET_PATH)
    elsif @local_indexer == 'solr'
      @logger.debug("SOLR HOST: " + LIBRARYFIND_SOLR_HARVESTING_URL)
    end 
    
    @logger.debug("DATABASE HOST " + @db[@dbtype]["host"])
    @logger.debug("DATABASE INFO: " + @db[@dbtype]["database"])
    
    #dbh = Mysql.real_connect(db[dbtype]["host"], db[dbtype]["username"], db[dbtype]["password"], db[dbtype]["database"])
    
    if defined? @db[@dbtype]["port"]
      ActiveRecord::Base.establish_connection(
      :adapter => @db[@dbtype]["adapter"],
      :host => @db[@dbtype]["host"],
      :username => @db[@dbtype]["username"],
      :password => @db[@dbtype]["password"],
      :database => @db[@dbtype]["database"]
      )
    else
      ActiveRecord::Base.establish_connection(
                                              :adapter => @db[@dbtype]["adapter"],
      :host => @db[@dbtype]["host"],
      :username => @db[@dbtype]["username"],
      :password => @db[@dbtype]["password"],
      :database => @db[@dbtype]["database"],
      :port => @db[@dbtype]["port"]
      )
    end
  end
  
  # Initalize variables
  :protected
  def init_config
    @logger.info("**** Initalizing production and development database configurations ****")
    @pusername= @db['production']['username']
    @ppassword = @db['production']['password']
    @pdatabase = @db['production']['database']
    @phost = @db['production']['host']
    
    @dusername = @db['development']['username']
    @dpassword = @db['development']['password']
    @ddatabase = @db['development']['database']
    @dhost = @db['development']['host']
  end
  
  # Grab the production environment indexes and data and store in test 
  :protected
  def backup_database
    init_config if @pusername.nil?
    begin
      @logger.info("Backing up database production")
      sucess = system("mysqldump --opt #{@pdatabase} -h #{@phost} > #{ENV['LIBRARYFIND_HOME']}/components/backup/database_#{Time.now().to_i}.sql -u#{@pusername} --password=#{@ppassword}")
      @logger.info("success:" + sucess.to_s)
      
      if !sucess
        raise "No backup save !"
      end
      
    rescue Exception => e
      @logger.error(e.message)
      raise e
    end
  end
  
  # Send the index to solr
  :protected
  def commit
    begin
      @index.send(Solr::Request::Commit.new)
      @index = Solr::Connection.new(LIBRARYFIND_SOLR_HARVESTING_URL, {:timeout => CFG_LF_TIMEOUT_SOLR})
#      @index.send(Solr::Request::Optimize.new)
#      @logger.info("[#{self.class}] : committed to solr #{@index.class}")
    rescue => err
      @logger.error("[#{self.class}] error committing to solr : #{err.message}")
      @logger.error("[#{self.class}] error committing to solr : #{err.backtrace.join('\n')}")
    end
  end
  
  :protected
  def save_log
    begin
      @logger.info("Update statistics")
      SaveLog.new
    rescue => e
      @logger.error("Errors statistics : #{e.message}")
    end
  end
  
  :protected
  def update_notice(_idD, dctitle, dccreator, dctype, ptitle, update_date)
    begin
      notice = Notice.getNoticeByDocId(_idD)
      if(!notice.nil?)
        notice.dc_title = dctitle
        notice.dc_author = dccreator
        notice.dc_type = dctype
        notice.ptitle = ptitle
        notice.update_date = update_date
        notice.save
      end
    rescue => e
      @logger.error("[CommonHarvester][update_notice] Error : " + e.message)
      @logger.error("[CommonHarvester][update_notice] Trace : " + e.backtrace.join("\n"))
      raise e
    end
  end
  
  def clean_solr_index(collection_id, ids=nil)
    if ids.nil? or ids.empty?
      @index.send(Solr::Request::Delete.new(:query => 'collection_id:('+collection_id.to_s+')'))
    else
      ids.each do |id|
        query = "id:(#{id};#{collection_id})"
        @index.send(Solr::Request::Delete.new(:query => query))
      end
    end
    @index.send(Solr::Request::Commit.new)
  end
  
  def clean_sql_data(collection_id, ids=nil)
    if ids.nil? or ids.empty?
      ActiveRecord::Base.connection.execute("delete from controls where collection_id=#{collection_id}")
      ActiveRecord::Base.connection.execute("delete from metadatas where collection_id=#{collection_id}")
      ActiveRecord::Base.connection.execute("delete from volumes where collection_id=#{collection_id}")
    else
      ActiveRecord::Base.connection.execute("delete from controls where collection_id=#{collection_id} and oai_identifier in (#{ids.join(",")})")
      ActiveRecord::Base.connection.execute("delete from metadatas where collection_id=#{collection_id} and dc_identifier in (#{ids.join(",")})")
      ActiveRecord::Base.connection.execute("delete from volumes where collection_id=#{collection_id} and dc_identifier in (#{ids.join(",")})")
    end
  end
  
end