# $Id: 005_create_cached_searches.rb 902 2007-03-27 06:50:40Z rordway $

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

class CreateCachedSearches < ActiveRecord::Migration
  def self.up
    create_table :cached_searches do |t|
      t.column :query_string,         :string
      t.column :query_type,           :string
      t.column :collection_set,       :string
      t.column :created_at,           :datetime
      t.column :in_cache,             :boolean, :default => false
      t.column :cache_updated_at,     :datetime
    end
    
    # Composite index across query_string, query_type, collection_set; be sure
    # to query in this order for most efficient mysql use.
    add_index :cached_searches, [:query_string, :query_type, :collection_set], :name => "query_set_index"
    
    add_index :cached_searches, :created_at
    
    # Composite index across cache_updated_at and in_cache
    add_index :cached_searches, [:cache_updated_at, :in_cache]

  end

  def self.down
    drop_table :cached_searches
  end
end
