# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
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
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

class Xpath
  # get all matching nodes
  def xpath_all(pdoc, path, namespace = '')
    case parser_type(pdoc)
      when 'libxml'
      if namespace!=""
        return pdoc.find(path, namespace) if pdoc.find(path, namespace)
      else
        return pdoc.find(path) if pdoc.find(path)
      end
      when 'nokogiri'
      if !namespace.blank?
        return pdoc.xpath(path, namespace) if pdoc.xpath(path, namespace)
      else
        return pdoc.xpath(path) if pdoc.xpath(path)
      end
      when 'rexml'
      if namespace!=""
        return REXML::XPath.match(pdoc, path, namespace)
      else
        return REXML::XPath.match(pdoc, path);
      end
    end
    return []
  end
  
  # get first matching node
  def xpath_first(doc, path, pnamespace = '')
    begin
      elements = xpath_all(doc, path, pnamespace)
      if elements != nil
        case parser_type(doc)
          when 'libxml'
          return elements.first
          when 'nokogiri'
          return elements.first
          when 'rexml'
          return elements[0]
        else
          return nil
        end
      else
        return nil
      end
    rescue
      return nil
    end
  end
  
  # get text for first matching node
  def xpath(pdoc, path, namespace = '')
    el = xpath_first(pdoc, path, namespace)
    return unless el
    case parser_type(pdoc)
      when 'libxml'
      return el.content
      when 'nokogiri'
      return el.content
      when 'rexml'
      return el.text
    end
    return nil
  end
  
  # get text for element)
  def xpath_get_text(doc)
    begin
      case parser_type(doc)
        when 'libxml'
        if doc.text? == false
          return doc.content
        else
          return ""
        end
        when 'nokogiri'
          return doc.content
        when 'rexml'
        if doc.has_text? == true
          return doc.text
        else
          return ""
        end
      end
    rescue
      return ""
    end
  end
  
  # get text for element)
  def xpath_get_all_text(doc)
    begin
      case parser_type(doc)
        when 'libxml'
        return doc.content
        when 'nokogiri'
        return doc.content
        when 'rexml'
        return doc.text
      end
    rescue
      return nil
    end
  end
  
  # get node/element name
  def xpath_get_name(doc)
    begin
      case parser_type(doc)
        when 'libxml'
        if doc.name != 'text'
          return doc.name
        else
          return nil
        end
        when 'nokogiri'
        if doc.name != 'text'
          return doc.name
        else
          return nil
        end
        when 'rexml'
        return doc.name
      end
    rescue
      return nil
    end
  end
  
  
  # figure out an attribute
  def get_attribute(node, attr_name)
    case parser_type(node)
      when 'rexml'
      return node.attribute(attr_name)
      when 'libxml'
      return node.attributes[attr_name]
      when 'nokogiri'
      return node.attributes[attr_name]
    end
    return nil
  end
  
  private
  
  # figure out what sort of object we should do xpath on
  def parser_type(x)
    
    str = x.class.to_s
    if str.starts_with?('Nokogiri')
      return 'nokogiri'
    end
    
    case x.class.to_s
      when 'LibXML::XML::Document'
      return 'libxml'
      when 'LibXML::XML::Node'
      return 'libxml'
      when 'LibXML::XML::Node::Set'
      return 'libxml'
      
      when 'XML::Document'
      return 'libxml'
      when 'XML::Node'
      return 'libxml'
      when 'XML::Node::Set'
      return 'libxml'
      
      when 'REXML::Element'
      return 'rexml'
      when 'REXML::Document'
      return 'rexml'
    end
  end
end
