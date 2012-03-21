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

class QueryController < ApplicationController
 #  web_service_dispatching_mode :direct
 #  web_service_api QueryApi
 #  wsdl_service_name 'query'
 #  web_service_scaffold :invoke

   def get_id(_id) 
     meta = MetaSearch.new()
     return meta.GetId(_id)
   end 

   def simple_search(_sets, _qtype, _arg, _start, _max) 
       meta = MetaSearch.new()
       _lqtype = Array.new
       _lqtype[0] = _qtype
       _larg = Array.new
       _larg[0] = _arg
       return meta.Search(_sets, _lqtype, _larg, _start, _max, nil, nil, nil, true)
   end 

   def search_async(_sets, _qtype, _arg, _start, _max)
       meta = MetaSearch.new()
       return meta.search_async(_sets, _qtype, _arg, _start, _max)
   end

   def simple_search_async(_sets, _qtype, _arg, _start, _max)
       meta = MetaSearch.new()
       _lqtype = Array.new
       _lqtype[0] = _qtype
       _larg = Array.new
       _larg[0] = _arg
       return meta.search_async(_sets, _lqtype, _larg, _start, _max)
   end
   
   def search(_sets, _qtype, _arg, _start, _max)
       meta = MetaSearch.new()
       return meta.Search(_sets, _qtype, _arg, _start, _max, nil,  nil, nil, true);
   end
 
   def search_ex(_sets, _qtype, _arg, _start, _max, session_id, action_type, data)
       meta = MetaSearch.new()
       return meta.Search(_sets, _qtype, _arg, _start, _max, session_id, action_type, nil, true);
   end

   def list_collections()
     meta = MetaSearch.new()
     return meta.ListCollections()
   end

   def list_groups()
     meta = MetaSearch.new()
     return meta.ListGroups()
   end

   def get_group_members(name)
     meta = MetaSearch.new()
     return meta.GetGroupMembers(name)
   end

   def check_job_status(_id)
     meta = MetaSearch.new()
     return meta.check_job_status(_id)
   end

   def check_jobs_status(_ids)
     meta = MetaSearch.new()
     return meta.check_job_status(_ids)
   end

   def kill_thread(_job_id, _thread_id)
     meta = MetaSearch.new()
     return meta.KillThread(_job_id, _thread_id)
   end

   def get_job_record(_id, _max)
     meta = MetaSearch.new()
     return meta.get_job_record(_id, _max)
   end

   def get_jobs_records(_ids, _max)
     meta = MetaSearch.new()
     return meta.get_jobs_records(_ids, _max)
   end
  
end
