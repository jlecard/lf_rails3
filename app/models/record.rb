#encoding: utf-8
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

class Record

  attr_accessor :rank, :hits, :ptitle, :title, :atitle, :isbn, :issn, :abstract,
                 :date, :author, :link, :id, :source, :doi, :openurl, :direct_url,
                 :thumbnail_url, :static_url, :subject, :publisher, :relation,
                 :contributor, :coverage, :rights, :callnum, :material_type, :format,
                 :vendor_url, :vendor_name, :volume, :issue, :number, :page, :start, :end,
                 :holdings, :raw_citation, :oclc_num, :theme, :category, :lang, :identifier,
                 :availability,:is_available, :examplaires,:notice,:actions_allowed,
                 :date_end_new,:date_indexed,:indice,:issue_title, :conservation, :binding, :issues
  
  def initialize(args=nil)
    if !args
      @rank = ""
      @hits = ""
      @ptitle = ""
      @title = ""
      @atitle = ""
      @isbn = ""
      @issn = ""
      @abstract = ""
      @date = ""
      @author = ""
      @link = ""
      @id = ""
      @source = ""
      @doi = ""
      @openurl = ""
      @direct_url = ""
      @thumbnail_url = ""
      @static_url = ""
      @subject = ""
      @publisher = ""
      @relation = ""
      @contributor = ""
      @coverage = ""
      @rights = ""
      @callnum = ""
      @material_type = ""
      @format = ""
      @vendor_name = ""
      @vendor_url = ""
      @volume = ""
      @issue = ""
      @number = ""
      @page = ""
      @start = ""
      @end = ""
      @holdings = ""
      @raw_citation = ""
      @oclc_num = ""
      @theme = ""
      @category = ""
      @lang = ""
      @identifier = ""
      @availability = ""
      @is_available = true
      @examplaires = []
      @notice = nil
      @actions_allowed = true
      @date_end_new = ""
      @date_indexed = ""
      @indice = ""
      @issue_title = ""
      @conservation = ""
    else
      args.each do |key, val|
        instance_variable_set("@#{key}", val)
      end  
    end
  end
end
