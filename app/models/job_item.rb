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
#
# == State of Jobs
#
class JobItem < ActionWebService::Struct
    member :job_id, :int # job_id
    member :record_id, :int # id cached_record
    member :thread_id, :int # process id
    member :target_name, :string # collection name
    member :hits, :int # hits
    member :total_hits, :int # total hits
    member :status, :int # state. ex: JOB_WAITING = 1, JOB_FINISHED = 0, JOB_ERROR = -1, JOB_PRIVATE = -2, JOB_STOPPED = -3, JOB_ERROR_TYPE = -4
    member :error, :string # message error
    member :timestamp , :string # time created
end
