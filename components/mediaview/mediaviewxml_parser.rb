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
require 'rubygems'
require 'nokogiri'
require 'xml'
#require 'components/autoformation'
require 'mediaview/mediaview_record'

class MediaviewXMLParser
  
  
  def initialize
    
  end

  
  def parseOAI(oaiXml)
    begin
   
    doc = Nokogiri::XML.parse(oaiXml)
    
    namespaces = {'dc' => 'http://purl.org/dc/elements/1.1/', 
      'dcterms' => 'http://purl.org/dc/terms/',
      'rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#"}
      
    titles = doc.xpath("//rdf:RDF/rdf:Description/dc:title", namespaces)
    
    titles.each do |title|
		if title != nil
		  title = title.content 
		  title = title.to_s.gsub('~',' ')
		  @metadata.title = title
		end
	end
    
    creators = doc.xpath("//rdf:RDF/rdf:Description/dc:creator", namespaces)
	creators.each do |creator|
		if creator != nil
		  creator = creator.content
		  creator = creator.to_s.gsub('~',' ')
		  creator = creator.to_s.gsub('¶',';')
		  creator = creator.to_s.gsub('|',';')
		  @metadata.creator = creator
		end
	end

    subjects = doc.xpath("//rdf:RDF/rdf:Description/dc:subject", namespaces)
	subjects.each do |subject|
		if subject != nil
		  subject = subject.content
		  subject = subject.to_s.gsub('~',' ')
		  subject = subject.to_s.gsub('¶',';')
		  subject = subject.to_s.gsub('|',';')
		  @metadata.subject = subject
		end
	end

    # Traitement special a faire pour la description a cause des ~
    descriptions = doc.xpath("//rdf:RDF/rdf:Description/dc:description", namespaces)
	descriptions.each do |description|
		if description != nil
		  description = description.content
		  description = description.to_s.gsub('~',' ')
		  description = description.to_s.gsub('¶',"\r\n")
		  @metadata.description = description
		  #puts "description: " + description
		end
	end
    
    publishers = doc.xpath("//rdf:RDF/rdf:Description/dc:publisher", namespaces)
	publishers.each do |publisher|
		if publisher != nil
		  publisher = publisher.content
		  publisher = publisher.to_s.gsub('~',' ')
		  @metadata.publisher = publisher
		  date = publisher.split(",")
		  if date != nil && (date.length() != 1)
			date = date[date.length() -1].to_s
			@metadata.date = date
		  end
		  #puts "publisher: " + publisher
		end
    end
	
    contributors = doc.xpath("//rdf:RDF/rdf:Description/dc:contributor", namespaces)
	contributors.each do |contributor|
		if contributor != nil
		  contributor = contributor.content
		  contributor = contributor.to_s.gsub('~',' ')
		  @metadata.contributor = contributor
		  #puts "contributor: " + contributor
		end
	end
    
    dates = doc.xpath("//rdf:RDF/rdf:Description/dc:date", namespaces)
	dates.each do |date|
		if date != nil
		  date = date.content
		  date = date.to_s.gsub('~',' ')
		  if @metadata.date == nil || @metadata.date == ""
			@metadata.date = date
		  end
		  #puts "date: " + date
		end
	end
    
    types = doc.xpath("//rdf:RDF/rdf:Description/dc:type", namespaces)
	types.each do |type|
		if type != nil
		  type = type.content
		  type = type.to_s.gsub('~',' ')
		  @metadata.type = type
		  #puts "type: " + type
		end
	end
    
    formats = doc.xpath("//rdf:RDF/rdf:Description/dc:format", namespaces)
	formats.each do |format|
		if format != nil
		  format = format.content
		  format = format.to_s.gsub('~',' ')
		  @metadata.format = format
		  #puts "format: " + format
		end
	end
    
    identifiers = doc.xpath("//rdf:RDF/rdf:Description/dc:identifier", namespaces)
	identifiers.each do |identifier|
		if identifier != nil
		  identifier = identifier.content
		  identifier = identifier.to_s.gsub('~',' ')
		  @metadata.identifier = identifier
		  #puts "identifier: " + identifier
		end
	end
    
    sources = doc.xpath("//rdf:RDF/rdf:Description/dc:source", namespaces)
	sources.each do |source|
		if source != nil
		  source = source.content
		  source = source.to_s.gsub('~',' ')
		  @metadata.source = source
		  #puts "source: " + source
		end
    end
	
    languages = doc.xpath("//rdf:RDF/rdf:Description/dc:language", namespaces)
	languages.each do |language|
		if language != nil
		  language = language.content
		  language = language.to_s.gsub('~',' ')
		  @metadata.language = language
		  #puts "language: " + language
		end
	end
    
    relations = doc.xpath("//rdf:RDF/rdf:Description/dc:relation", namespaces)
	relations.each do |relation|
		if relation != nil
		  relation = relation.content
		  relation = relation.to_s.gsub('~',' ')
		  @metadata.relation = relation
		  #puts "relation: " + relation
		end
	end
    
    coverages = doc.xpath("//rdf:RDF/rdf:Description/dc:coverage", namespaces)
	coverages.each do |coverage|
		if coverage != nil
		  coverage = coverage.content
		  coverage = coverage.to_s.gsub('~',' ')
		  @metadata.coverage = coverage
		  #puts "coverage: " + coverage
		end
	end
    
    rightss = doc.xpath("//rdf:RDF/rdf:Description/dc:rights", namespaces)
	rightss.each do |rights|
		if rights != nil
		  rights = rights.content
		  rights = rights.to_s.gsub('~',' ')
		  @metadata.rights = rights
		  #puts "rights: " + rights
		end
	end
	
  rescue => e
      puts "ERROR : #{e.message}"
      return
    end
   
  end



  def parseMediaView(mediaviewXml)
    begin
     
      doc = Nokogiri::XML.parse(mediaviewXml)
      
      namespaces = {'mvmdb' => 'http://www.ineoms.com/xml/mvmdb-1.0',
        'rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#"}
        
      callnumbers = doc.xpath("//rdf:RDF/rdf:Description/mvmdb:callnumber", namespaces)
	  callnumbers.each do |callnumber|
		  if callnumber != nil
			callnumber = callnumber.content
			callnumber = callnumber.to_s.gsub('~',' ')
			@metadata.callnumber = callnumber
			#puts "title: " + title
		  end
	  end
  
      types = doc.xpath("//rdf:RDF/rdf:Description/mvmdb:bpidocumenttype", namespaces)
	  types.each do |type|
		  if type != nil
			type = type.content
			type = type.to_s.gsub('~',' ')
			if type.index('import 204 $a') != nil
			  type = ""
			end
			@metadata.type = type
		  end
	  end
      
      links = doc.xpath("//rdf:RDF/rdf:Description/mvmdb:link/mvmdb:url", namespaces)
	  links.each do |link|
		  if link != nil
			link = link.content
			link = link.to_s.gsub('~',' ')
			if @metadata.link == nil || @metadata.link == ""
			  @metadata.link = link
			end
			#puts "creator: " + creator
		  end
	  end
      
      volumes = doc.xpath("//rdf:RDF/rdf:Description/mvmdb:bpiphysicaldesc", namespaces)
	  volumes.each do |volume|
		  if volume != nil 
			volume = volume.content
			volume = volume.to_s.gsub('~',' ')
			volume = volume.to_s.gsub('¶',"\r\n")
			if volume.index('import 215 $a') != nil
			  volume = ""
			end
			@metadata.volume = volume
			#puts "creator: " + creator
		  end
	  end
	  
    rescue => e
      puts "ERRREUR : #{e.message}"
      return
    end
   
  end  
  
  
  ##
  ## return 
  ##
  def parse_fields(row, collection_id)
    @metadata = MediaviewRecord.new
    @metadata.id = row.id
    @metadata.collection_id = collection_id
    parseOAI(row.xmldublincore)
    parseMediaView(row.xmlmediaview)
    @metadata.theme = row.theme
    @metadata.category = row.category
    @metadata.rights = row.message
    #puts ("***Document Message : #{@metadata.rights}")
    return @metadata
  end

  
 
  def getOaiXML
    _obj = Autoformation.new
    _result = _obj.get_data_for_id(4575)
    return _result.xmldublincore
    
#    "<?xml version=\"1.0\" encoding=\"utf-8\"?>
# <!-- XML DublinCore -->
#<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
#  <rdf:Description>
#    <dc:title>Chimie 1ère S [cédérom]~: tout le programme de l'année scolaire</dc:title>
#    <dc:creator></dc:creator>
#    <dc:subject>Chimie~- Didacticiels</dc:subject>
#    <dc:description>Scolaire~- 1 cédérom¶Les différents chapitres comprennent des rappels de cours, des questions de compréhension et des séries d'exercices.¶¶A consulter sur~: Poste informatique : Didacticiel-Autoformation¶1 licence(s)</dc:description>
#  <dc:publisher>Génération 5, 2000</dc:publisher>
#  <dc:contributor></dc:contributor>
#  <dc:date></dc:date>
#  <dc:type></dc:type>
#  <dc:format></dc:format>
#  <dc:identifier></dc:identifier>
#  <dc:source></dc:source>
#  <dc:language></dc:language>
#  <dc:relation></dc:relation>
#  <dc:coverage></dc:coverage>
#  <dc:rights></dc:rights>
#  </rdf:Description>
#</rdf:RDF>"
  end

  def getMediaviewXML
    _obj = Autoformation.new
    _result = _obj.get_data_for_id(4575)
    return _result.xmlmediaview
    
#    "<?xml version=\"1.0\" encoding=\"utf-8\"?>
#<!-- XML MediaView -->
#<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:mvmdb=\"http://www.ineoms.com/xml/mvmdb-1.0\">
#    <rdf:Description>
#    <mvmdb:searchtitle></mvmdb:searchtitle>
#    <mvmdb:searchauthor></mvmdb:searchauthor>
#    <mvmdb:searchsubject></mvmdb:searchsubject>
#    <mvmdb:collection></mvmdb:collection>
#    <mvmdb:callnumber>54</mvmdb:callnumber>
#    <mvmdb:shortdescription>Scolaire~- Programme de chimie de 1ère S¶A consulter sur~: Poste informatique : Didacticiel-Autoformation</mvmdb:shortdescription>
#    <mvmdb:keywords>Chimie 1ère S [cédérom]~: tout le programme de l'année scolaire¶Chimie~- Didacticiels¶Les différents chapitres comprennent des rappels de cours, des questions de compréhension et des séries d'exercices.¶Scolaire¶Génération 5</mvmdb:keywords>
#    <mvmdb:bpikeywords></mvmdb:bpikeywords>
#    <!-- links -->
#    <mvmdb:bpiissn>import 11 $a</mvmdb:bpiissn>
#    <mvmdb:bpiaccess></mvmdb:bpiaccess>
#    <mvmdb:bpilicences>import 310 $a</mvmdb:bpilicences>
#    <mvmdb:bpicopyrights>import 325 $a</mvmdb:bpicopyrights>
#    <mvmdb:bpitype></mvmdb:bpitype>
#    <mvmdb:bpilinksdir>false</mvmdb:bpilinksdir>
#    <mvmdb:bpidocumenttype>DIDACTIC</mvmdb:bpidocumenttype>
#    <!-- csBPITypeDocument -->
#    <mvmdb:bpiphysicaldesc>import 215 $a</mvmdb:bpiphysicaldesc>
#    <mvmdb:bpiconfigtypelike>DIDACTICIEL</mvmdb:bpiconfigtypelike>
#    <!-- csBPITypeLogiqueLike -->
#    <mvmdb:bpistatcategory></mvmdb:bpistatcategory>
#    <!-- csBPICategorieStatistique -->
#    <mvmdb:bpislip>DIDACT</mvmdb:bpislip>
#    <!-- csBPIBordereau -->
#    <mvmdb:bpidomainlang></mvmdb:bpidomainlang>
#    <!-- csBPIFamLangueDomaine -->
#    <mvmdb:bpisubjectlang></mvmdb:bpisubjectlang>
#    <!-- csBPILangueMatiere -->
#    <mvmdb:bpisuggestedpw>false</mvmdb:bpisuggestedpw>
#    <mvmdb:link>
#      <mvmdb:label>Description du document</mvmdb:label>
#      <mvmdb:url>http://ssur-eaf.ck.bpi.fr/DocEaf/Didacticiels/chimie_1ere_S.htm</mvmdb:url>
#    </mvmdb:link>
#  </rdf:Description>
#</rdf:RDF>"
  end
  
end

#test = MediaviewXMLParser.new()
#record = test.parse_fields(4575, test.getMediaviewXML, test.getOaiXML)
#puts record.title
