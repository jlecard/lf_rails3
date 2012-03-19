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

class Record < ActionWebService::Struct
    member :rank, :string
    member :hits, :string
    member :ptitle, :string
    member :title, :string
    member :atitle, :string
    member :isbn, :string
    member :issn, :string
    member :abstract, :string
    member :date, :string
    member :author, :string
    member :link, :string
    member :id, :string
    member :source, :string
    member :doi, :string
    member :openurl, :string
    member :direct_url, :string
    member :thumbnail_url, :string
    member :static_url, :string
    member :subject, :string
    member :publisher, :string
    member :relation, :string
    member :contributor, :string
    member :coverage, :string
    member :rights, :string
    member :callnum, :string
    member :material_type, :string
    member :format, :string
    member :vendor_name, :string
    member :vendor_url, :string
    member :volume, :string
    member :binding, :string
    member :issue, :string
    member :issues, :string
    member :number, :string
    member :page, :string
    member :start, :float
    member :end, :float
    member :holdings, :string
    member :raw_citation, :string
    member :oclc_num, :string
    member :theme, :string
    member :category, :string
    member :lang, :string
    member :identifier, :string
    member :availability, :string
    member :is_available, :boolean
    member :examplaires, [Struct::Examplaire]
    member :notice, Struct::NoticeStruct
    member :actions_allowed, :boolean
    member :date_end_new, :datetime
    member :date_indexed, :datetime
    member :indice, :string
    member :issue_title, :string
    member :conservation, :string
    
		def initialize
      super  
			self.rank = "";
			self.hits = "";
			self.ptitle = "";
			self.title = "";
			self.atitle = "";
			self.isbn = "";
			self.issn = "";
			self.abstract = "";
			self.date = "";
			self.author = "";
			self.link = "";
			self.id = "";
			self.source = "";
			self.doi = "";
			self.openurl = "";
			self.direct_url = "";
			self.thumbnail_url = "";
			self.static_url = "";
			self.subject = "";
			self.publisher = "";
			self.relation = "";
			self.contributor = "";
			self.coverage = "";
			self.rights = "";
			self.callnum = "";
			self.material_type = "";
			self.format = "";
			self.vendor_name = "";
			self.vendor_url = "";
			self.volume = "";
			self.issue = "";
			self.number = "";
			self.page = "";
			self.start = "";
			self.end = "";
			self.holdings = "";
			self.raw_citation = "";
			self.oclc_num = "";
			self.theme = "";
			self.category = "";
			self.lang = "";
			self.identifier = "";
      self.availability = "";
      self.is_available = true;
      self.examplaires = [];
      
      self.notice = nil
      self.actions_allowed = true;
      self.date_end_new = "";
      self.date_indexed = "";
      self.indice = "";
      self.issue_title = "";
      self.conservation = "";
		end

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
