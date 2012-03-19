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
# This program tries to connect to the PostgreSQL and MySQL databases and fetches data


class Bpi_connector < ActionController::Base
  
  require 'rubygems'
  begin
    require 'dbi'  
  rescue LoadError => e
    logger.warn("No dbi gem")
  end
  require 'xml'
  require 'mediaview/mediaviewxml_parser'
  
  def initialize
    super
    @database = ""
    restart
  end
  
  def disconnect
    if @conn != nil
      @conn.disconnect
    end
  end
  
  def connect_to_postgresql(database,host,username,password)
    @database = database
    _host = host
    _user = username
    _password = password
    _uri = "DBI:Pg:database=#{@database};host=#{_host}"
    logger.debug("\nConnecting to Postgres...")
    @conn = DBI.connect(_uri, _user, _password)
    logger.debug("connection  done to postgres database : #{@database}")
    return @conn
  end
  
  
  def fetch_data(connection, query, dataset)
    _connection = connection
    #query = dbh.prepare("SELECT txmldublincore,txmlmediaview FROM tl_document WHERE (apkid=821)")
    _query = _connection.prepare(query)
    _query.execute()
    i = 0
    logger.debug("[fetch_data]")
    while row = _query.fetch() do
      _rec = MediaviewData.new
      _rec.id = row[0]
      _rec.xmldublincore = row[1]
      _rec.xmlmediaview = row[2]
      logger.debug("[fetch_data] get_themes")
      _rec.theme = get_themes(_connection, row[0], @database)
      logger.debug("[fetch_data] get_categories")
      _rec.category = get_categories(_connection, row[0])
      logger.debug("[fetch_data] get_message")
      _rec.message = get_message(_connection, row[0])
      dataset.insert(i,_rec)
      i+= 1 
    end
    logger.debug("[fetch_data] return dataset")
    return dataset
  end
  
  
  def get_data()
    @query = "SELECT DISTINCT apkid,txmldublincore,txmlmediaview FROM tl_document WHERE boactive = true;"
    begin
      @dataset = Array.new
      @dataset = fetch_data(@conn,@query, @dataset)
    rescue
      logger.debug "Error while processing : #{$!}"
    end
    return @dataset
  end
  
  def get_data_from_ids(listId)
    @query = "SELECT DISTINCT apkid,txmldublincore,txmlmediaview FROM tl_document WHERE boactive = true AND (#{listId});"
    @dataset = Array.new
    @dataset = fetch_data(@conn,@query, @dataset)
    return @dataset
  end
  
  
  def get_parent_themes(connection, th_label, ifkparentid, level)
    begin
      logger.debug("[get_parent_themes] label: #{th_label} ifkparentid: #{ifkparentid} level #{level}")
      if ifkparentid == 0 or level <= 3
        logger.debug("[get_parent_themes] return label: #{th_label} ifkparentid: #{ifkparentid}")
        return th_label, ifkparentid
      else
        req = "SELECT th.ifkparentid as parentid, th.stlabell1 as theme, ilevel as level from tl_theme as th WHERE apkid = #{ifkparentid}"
        query = connection.prepare(req)
        query.execute()
        row = query.fetch()
        t, l = get_parent_themes(connection, row['theme'], row['parentid'], row['level'])
        return t.to_s + THEME_SEPARATOR + th_label.to_s, l.to_s
      end
    rescue => e
      logger.error("[get_parent_themes] error : #{e.message}")
      logger.error($!.backtrace)
      return th_label
    end 
  end
  
  def get_themes(connection, apkid, source)
    
    begin
      
      logger.debug("[get_themes] ## apkid: #{apkid} source: #{source} ##")
      _themes = []
      
      req = "SELECT th.ifkparentid as parentid, th.stlabell1 AS theme, ilevel as level, th.apkid as id FROM tr_documenttheme AS trdoc LEFT JOIN tl_document AS doc ON trdoc.ifkdocumentid = doc.apkid LEFT JOIN tl_theme AS th ON trdoc.ifkthemeid = th.apkid WHERE trdoc.ifkdocumentid = '#{apkid}'"
      _query = connection.prepare(req)
      _query.execute()
      
      i = 0
      while row = _query.fetch() do
        
        _label = ""
        i += 1
        logger.debug("[get_themes] level: #{row['level']} apkid_theme : #{row['id']} apkid_theme_parent : #{row['parentid']}")
        
        if row['level'] > 3
          _label, parent = get_parent_themes(connection, row['theme'], row['parentid'], row['level'])
        elsif row['level'] == 3
          parent = row['id']
          _label = row['theme']
        else
          parent = row['id']
        end
        
        # format with database
        _ref = parent.to_s
        
        logger.debug("[get_themes] label: #{_label} ref_source: #{_ref}")
        
        _r = ThemesReference.match_theme_references_with_ref_source(_ref, @database, 0)
        if !_r.nil? and !_r.empty?
          _r.each do |ref|
            _s = ""
            logger.debug("[get_themes] reference found ! #{ref.ref_theme}")
            _s = ref.name_theme()
            
            if (!_s.blank? and !_label.blank?)
              _s += THEME_SEPARATOR + _label.capitalize
            end
            
            if (!_s.nil? and !_themes.include?(_s))
              logger.debug("[get_theme] add theme : #{_s}")
              _themes << _s
            end
          end
        else
          logger.debug("[get_themes] ##### nothing reference for #{_ref} and notice : #{apkid}")
          @indiceNotMatched << apkid.to_s + " => " + _ref.to_s
          @error += 1
        end
      end
      
      _retour = ""
      i = 0
      _themes.each do |v|
        
        if i != 0
          _retour += ";"
        end
        
        _retour += v
        
        i += 1
      end
      
      if !_retour.blank?
        @matched += 1
      end
      
      logger.debug("[get_themes] ## retour: #{_retour}")
      return _retour
      
    rescue Exception => e
      logger.error("[get_themes] ## Can't get themes #{e.message}")
      logger.error($!.backtrace)
      return ""
    end
  end
  
  def get_categories(connection, apkid)
    begin
      _category = ""
      req = "SELECT th.stlabel AS category FROM tr_documentcategory AS trdoc LEFT JOIN tl_document AS doc ON trdoc.ifkdocumentid = doc.apkid LEFT JOIN tl_category AS th ON trdoc.ifkcategoryid = th.apkid WHERE trdoc.ifkdocumentid = '#{apkid}'"
      _query = connection.prepare(req)
      _query.execute()
      i = 0
      while row = _query.fetch() do
        if i != 0
          _category += ';'
        end
        i += 1
        _category += row['category']
      end
      return _category
    rescue
      logger.debug("Can't get categories #{$!}")
      return ""
    end
  end
  
  def get_message(connection, apkid)
    begin
      _query = "SELECT tmessagel1 FROM tl_displaymessage where apkid = (SELECT ifkintradisplaymessageid FROM tl_document WHERE apkid = #{apkid})"
      _query = connection.prepare(_query)
      _query.execute()
      #      while row = _query.fetch() do
      #        @message = row.to_s
      #      end
      @message = _query.fetch().to_s
      return @message
    rescue
      logger.debug("Can't get document message : #{$!}")
      return ""
    end
  end
  
  def get_parsed_data(collection_id)
    _data = get_data()
    @parsed_records = Array.new
    i = 0
    logger.debug("Start parse data #{_data.size}")
    _data.each {|row|
      _parser = MediaviewXMLParser.new
      logger.debug("i = #{i} ID: #{row.id}")
      @parsed_records.insert(i,_parser.parse_fields(row, collection_id))
      i += 1
    }
    return @parsed_records
  end
  
  def get_parsed_data_from_ids(listId, collection_id)
    _parser = MediaviewXMLParser.new
    _data = get_data_from_ids(listId)
    @parsed_records = Array.new
    i = 0
    begin
      _data.each {|row|
        @parsed_records.insert(i,_parser.parse_fields(row, collection_id))
        i += 1
      }
    rescue
      logger.debug "ERREUR #{$!}"
    end
    return @parsed_records    
  end
  
  
  def get_document_source(connection,documentID)
    begin
      _docID = documentID
      _conn = connection   
      logger.info("This.Document id = " + _docID.to_s)
      _multimediaID = getMultimediaID(_conn,_docID)
      _objectName = getObjectName(_conn,_multimediaID[0])
      #_objectName = "Web"
      #logger.debug("Multimedia ids :" + _multimediaID[0].to_s + "," +  _multimediaID[1].to_s)
      @source = Array.new
      #_table = "tl_oweb"
      #_query = "SELECT sturlhost FROM #{_table} WHERE ifkomultimediaid = (SELECT ifkomultimediaid FROM tr_documentomultimedia WHERE ifkdocumentid = #{_docID})"
      if _objectName == "Application"
        _multimediaID.each { |id|
          _query = "SELECT stapplicationcommandline FROM tl_oapplication WHERE ifkomultimediaid = #{id}"
          _query = _conn.prepare(_query)
          _query.execute()  
          i = 0
          while row = _query.fetch() do
            if i != 0
              @source += ";"
            end
            i+= 1
            @source += row
          end
          @source << row.to_s
        }
      elsif _objectName == "Web"
        _multimediaID.each { |id|
          _query = "SELECT sturlhost FROM tl_oweb WHERE ifkomultimediaid = #{id}"
          _query = _conn.prepare(_query)
          _query.execute()
          row = _query.fetch()
          @source << row.to_s
        }
      elsif _objectName == "Audio vidéo numérisé"
        _multimediaID.each { |id|
          _query1 = "SELECT ifkserverid, stuncpath FROM tl_odigitizedaudiovideocopy WHERE ifkodigitizedaudiovideoid = (SELECT apkid from tl_odigitizedaudiovideo WHERE ifkomultimediaid = #{id})"
          _query1 = _conn.prepare(_query1)
          _query1.execute()
          rowset = _query1.fetch()
          _query = "SELECT stodigitizedaudiovideourlroot FROM tl_server WHERE apkid= #{rowset[0]}"
          _query = _conn.prepare(_query)
          _query.execute()
          row = _query.fetch()
          #src = row.to_s + "/" + rowset[1].to_s
          @source << row.to_s
        }
      elsif _objectName == "CD audio - DVD vidéo"
        _query = ""
        @source << "Demander à la bibliothèque"
      elsif _objectName == "Document électronique"
        _query = ""
        @source << "Pas de Lieu"
      elsif _objectName == "Objet non diffusable"
        @source << "Pas de Lieu"
      end
      #_query = "SELECT sturlhost FROM tl_oweb WHERE ifkomultimediaid = (SELECT ifkomultimediaid FROM tr_documentomultimedia WHERE ifkdocumentid = #{_docID})"
      #@source = _query.fetch()
      return _objectName, @source
    rescue
      #return nil #("Source not found !")
      logger.debug("Error : #{$!}")
      return nil
    end
  end
  
  def getMultimediaID(connection, documentID)
    begin
      _id = documentID
      _conn = connection 
      _query = "SELECT ifkomultimediaid FROM tr_documentomultimedia WHERE ifkdocumentid = #{_id}"
      _query = _conn.prepare(_query)
      _query.execute()
      multimediaID = Array.new
      while row = _query.fetch() do
        multimediaID << row
      end
      #multimediaID = _query.fetch()
      #logger.debug("MultiMedia id :" + multimediaID.to_s)
      return multimediaID
    rescue
      logger.debug("Sorry!! Cannot return Multimedia Id ")
    end
  end
  
  def getObjectName(connection,multimediaID)
    _multimediaID = multimediaID
    _conn = connection
    _query = "SELECT ifkobjecttypeid FROM tl_omultimedia WHERE apkid = #{_multimediaID}"
    _query = _conn.prepare(_query)
    _query.execute()
    _id = _query.fetch()    
    #logger.debug("object id :"+_id.to_s)
    #_tableName = ""
    
    case _id.to_s     
      when "1"
      return "Application"
      when "2"
      return "Web"
      when "3"
      return "Audio vidéo numérisé"
      when "4"
      return "CD audio - DVD vidéo"
      when "5"
      return "Document électronique"
    else
      return "Objet non diffusable"        
    end 
  end
  
  def restart
    @error = 0
    @indiceNotMatched = Array.new()
    @matched = 0
  end
  
  def matched
    return @matched
  end
  
  def errors
    return @error
  end
  
  def indices_no_match
    return @indiceNotMatched
  end
  
end
