# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Innovation
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
require 'active_record'
require 'active_record/base'

class RssFeed < ActiveRecord::Base
 
  has_many :subscriptions,      :foreign_key => :object_uid, :conditions => " object_type = #{ENUM_RSS_FEED} "
  
 
  def self.getRssFeedById(rss_feed_id)
    return RssFeed.find(:first, :conditions => "#{rss_feed_id}" )
  end
  
  def self.getRssFeeds(new_docs, isbn_issn_not_null, collection_group)
    conditions = ""
    if(new_docs == NEW_DOCS)
      conditions = " new_docs = #{NEW_DOCS} "
    end
    if(isbn_issn_not_null == ISBN_ISSN_NOT_NULL)
      if(conditions != "")
        conditions += " and "
      end
      conditions += " isbn_issn_nullable = #{isbn_issn_not_null} "
    end
    if(!collection_group.nil?)
      if(conditions != "")
        conditions += " and "
      end
      conditions += " collection_group = #{collection_group} "
    end
    
    if(conditions == "")
      return RssFeed.find(:all)
    else
      return RssFeed.find(:all, :conditions => " #{conditions} ")
    end
  end
  
end
