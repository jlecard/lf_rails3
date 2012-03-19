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

class CreateMetadatas < ActiveRecord::Migration 
  
  def self.up
    create_table :metadatas do |t|
      t.column :collection_id,	:int
      t.column :controls_id,	:int
      t.column :dc_title,             :text
      t.column :dc_creator,	:text
      t.column :dc_subject,	:text
      t.column :dc_description, 	:text
      t.column :dc_publisher, 	:text
      t.column :dc_contributor, 	:text 
      t.column :dc_date, 	:text
      t.column :dc_type,	:text
      t.column :dc_format, 	:text
      t.column :dc_identifier, 	:text
      t.column :dc_source, 	:text
      t.column :dc_relation, 	:text
      t.column :dc_coverage, 	:text
      t.column :dc_rights,	:text
      t.column :osu_volume, :text
      t.column :osu_issue, :text
      t.column :osu_linking, :text 
      t.column :osu_openurl,             :string
    end

    add_index :metadatas, :collection_id
    add_index :metadatas, :controls_id
  end

  def self.down
    drop_table :metadatas
  end
end
