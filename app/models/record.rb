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

class ApiResource < ActiveResource::Base
  self.site = 'http://test.host:3000'
end

class Record < ApiResource
  cattr_accessor :rank, :hits, :ptitle, :title, :atitle, :isbn, :issn, :abstract,
                 :date, :author, :link, :id, :source, :doi, :openurl, :direct_url,
                 :thumbnail_url, :static_url, :subject, :publisher, :relation,
                 :contributor, :coverage, :rights, :callnum, :material_type, :format,
                 :vendor_url, :vendor_name, :volume, :issue, :number, :page, :start, :end,
                 :holdings, :raw_citation, :oclc_num, :theme, :category, :lang, :identifier,
                 :availability,:is_available, :examplaires,:notice,:actions_allowed,
                 :date_end_new,:date_indexed,:indice,:issue_title, :conservation
                 
  self.element_name = "record"
  self.rank = ""
  self.hits = ""
  self.ptitle = ""
  self.title = ""
  self.atitle = ""
  self.isbn = ""
  self.issn = ""
  self.abstract = ""
  self.date = ""
  self.author = ""
  self.link = ""
  self.id = ""
  self.source = ""
  self.doi = ""
  self.openurl = ""
  self.direct_url = ""
  self.thumbnail_url = ""
  self.static_url = ""
  self.subject = ""
  self.publisher = ""
  self.relation = ""
  self.contributor = ""
  self.coverage = ""
  self.rights = ""
  self.callnum = ""
  self.material_type = ""
  self.format = ""
  self.vendor_name = ""
  self.vendor_url = ""
  self.volume = ""
  self.issue = ""
  self.number = ""
  self.page = ""
  self.start = ""
  self.end = ""
  self.holdings = ""
  self.raw_citation = ""
  self.oclc_num = ""
  self.theme = ""
  self.category = ""
  self.lang = ""
  self.identifier = ""
  self.availability = ""
  self.is_available = true
  self.examplaires = []
  self.notice = nil
  self.actions_allowed = true
  self.date_end_new = ""
  self.date_indexed = ""
  self.indice = ""
  self.issue_title = ""
  self.conservation = ""


  def self.normalizeLang(lang)
    if lang == nil
      return ""
    end
    case lang.downcase
    when "fr"
      return "Francais"
    when "fr_fr"
      return "Francais"
    when "en"
      return "Anglais"
    when "en_en"
      return "Anglais"
    when "en_us"
      return "Anglais"
    when "us"
      return "Anglais"
    when "us_us"
      return "Anglais"
    when "fre"
      return "Francais"
    else
    return ""
    end
  end

end
