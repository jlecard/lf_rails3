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

class QueryApi < ActionWebService::API::Base
   api_method :get_id, :expects => [{:id => :string}], :returns => [Record]
   api_method :search, :expects => [{:sets => :string},{:type => [:string]}, {:query => [:string]},{:start => :int},{:max => :int}], :returns => [[Record]]
   api_method :search_ex, :expects => [{:sets => :string},{:type => [:string]}, {:query => [:string]},{:start => :int},{:max => :int},{:session_id => :string},{:action_type => :string},{:data => :string}], :returns => [[Record]]
   api_method :simple_search, :expects => [{:sets => :string}, {:type => :string}, {:query => :string}, {:start => :int}, {:max => :int}], :returns => [[Record]]
   api_method :list_collections, :returns => [[CollectionList]]
   api_method :list_groups, :returns => [[GroupList]]
   api_method :get_group_members, :expects => [{:name => :string}], :returns => [GroupList]
   api_method :search_async, :expects => [{:sets => :string},{:type => [:string]}, {:query => [:string]},{:start => :int},{:max => :int}], :returns => [[:int]]
   api_method :simple_search_async, :expects => [{:sets => :string}, {:type => :string}, {:query => :string}, {:start => :int}, {:max => :int}], :returns => [[:int]]
   api_method :check_jobs_status, :expects => [{:jobid => [:int]}], :returns => [[JobItem]]
   api_method :check_job_status, :expects => [{:jobid => :int}], :returns => [JobItem]
   api_method :get_job_record, :expects => [{:jobid => :int}, {:max => :int}], :returns => [[Record]]
   api_method :get_jobs_records, :expects => [{:jobids => [:int]}, {:max => :int}], :returns => [[Record]]
   api_method :kill_thread, :expects => [{:jobid => :int}, {:threadid => :int}], :returns => [:int]
end
