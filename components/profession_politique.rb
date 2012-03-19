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
require 'open-uri'
require 'libxml'


class ProfessionPolitique
  attr_accessor :id, :date, :description, :title, :author, :link, :type, :subject, :publisher
  FEEDS_URL = 'http://nominations.acteurspublics.com/xml/feed'
  
  # Parse the xml daily feeds stream. Returns an array of ProfPolRecords
  def self.parse(logger, hostproxy = nil, portproxy = nil)
    documents = Array.new
    begin
      xml_content = nil 
      
      logger.info("[#{self.name}] Contact : #{FEEDS_URL}")
      if !hostproxy.nil?
        logger.info("[#{self.name}] use proxy : #{hostproxy}")
        xml_content = Net::HTTP::Proxy(hostproxy.to_s, portproxy.to_s).get_response(URI.parse(FEEDS_URL))
      else
        xml_content = Net::HTTP.get_response(URI.parse(FEEDS_URL))
      end
      xml_doc = LibXML::XML::Parser.string(xml_content.body, 
                                           :encoding => LibXML::XML::Encoding::UTF_8, 
                                           :options => LibXML::XML::Parser::Options::NOCDATA)
      doc = xml_doc.parse
      nodes = doc.find("//item")
      nodes.each do |node|
        current_record = ProfessionPolitique.new
        current_record.id = node.attributes['id'].to_s
        node.children.each do |child|
          case child.name
            when "titre"
            current_record.title = child.content
            when "date"
            # TODO : warning format is "9 juin, 2010 - 07:00"
            current_record.date = parseDate(child.content)
            logger.debug("[ProfessionPolitique] [parse] date : #{current_record.date}")
            when "chapeau"
            current_record.description = child.content
            when "link"
            current_record.link = child.content
            when "type"
            current_record.type = child.content
            when "rubrique"
            current_record.subject = child.content 
            when "texte"
            current_record.description = child.content if current_record.description.nil?
            when "publication"
            current_record.publisher = child.content 
          else
            logger.warn("[#{self.name}] : tag #{child.name} has not been processed")
          end
        end
        documents.push(current_record)
      end
    rescue => e
      logger.error("[#{self.name}] : #{e.message}")
      logger.error("[#{self.name}] : #{e.backtrace.join("\n")}")
    end
    logger.debug("[#{self.name}] ready to index: #{documents.size} documents")
    return documents
  end
  
  def self.parseDate(str)
    # "warning format is "9 juin, 2010 - 07:00"
    
    return "" if str.blank?
    
    index = str.split(" ")
    v = ""
    if (index.length >= 2)
      yyyy = index[2]
      mm = index[1]
      dd = index[0]
      
      if !mm.nil?
        if mm.starts_with?("ja")
          mm = "01"
        elsif mm.starts_with?("f")
          mm = "02"
        elsif mm.starts_with?("mar")
          mm = "03"
        elsif mm.starts_with?("av")
          mm = "04"
        elsif mm.starts_with?("mai")
          mm = "05"
        elsif mm.starts_with?("juin")
          mm = "06"
        elsif mm.starts_with?("juil")
          mm = "07"
        elsif mm.starts_with?("ao")
          mm = "08"
        elsif mm.starts_with?("s")
          mm = "09"
        elsif mm.starts_with?("o")
          mm = "10"
        elsif mm.starts_with?("n")
          mm = "11"
        elsif mm.starts_with?("d")
          mm = "12"
        else
          mm = "00"
        end
      end
      v = "#{yyyy}#{mm}#{dd}"
    end
    
    return v
  end
  
  
end
