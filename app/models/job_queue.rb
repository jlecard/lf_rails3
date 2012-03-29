# $Id: cached_search.rb 1020 2007-07-31 05:50:42Z reeset $

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

# Use to be cached_searches.  Moved to 
# accom. rails naming convention*


class JobQueue < ActiveRecord::Base
  has_many :cached_records
  
  def self.check_status (id)
    begin
      uncached do 
        return JobQueue.find(id)
      end
    rescue => e
      logger.error("[JobQueue] check_status : #{e.message} => #{id}")
      return nil
    end
  end
  
  def self.update_job (id, rec_id, database_name = '', mystatus = 0, hits = 0, total_hits = 0, myerror = "")
    begin
      objRecord = JobQueue.find(id ,:lock=>false)
      logger.info("[job_queue][update_job] JOBRECORD ID #{id} : #{objRecord}")
      logger.info("[job_queue][update_job] rec_id : #{rec_id}")
      return nil if objRecord == nil
      objRecord.records_id = rec_id
      if !database_name.blank?
        objRecord.database_name = database_name
      end
      objRecord.status = mystatus.to_i 
      objRecord.hits = hits.to_i
      objRecord.total_hits = total_hits.to_i
      objRecord.error = myerror
      objRecord.timestamp = "#{DateTime::now().to_f}"
      objRecord.save
      logger.info("[job_queue][update_job] Update JOB ID #{id} : #{objRecord.status} time : #{objRecord.timestamp}")
      return 1
    rescue => e
      logger.error("[job_queue][update_job] Error on JOBRECORD ID #{id} : #{objRecord} : #{e.message}")
      logger.debug("[job_queue][update_job] Backtrace : #{e.backtrace.join("\n")}")
      return nil
    end
  end
  
  def self.update_thread_id (id, thread_id) 
    begin
      objRecord = JobQueue.find(id,:lock=>true)
      return nil if objRecord == nil
      objRecord.thread_id = thread_id
      objRecord.save
      return 1
      raise
      return nil
    end
  end
  
  def self.create_job(collection_id, rec_id = -1, thread_id = -1, database_name="nil", mystatus=1, myhits = 0, myerror="")
    objSearch = JobQueue.new(:collection_id => collection_id, :records_id => rec_id, 
                            :thread_id => thread_id,  :database_name => database_name, 
                            :status => mystatus, :hits => myhits, :error => myerror,
                            :timestamp=>DateTime::now().to_f)
    objSearch.save(:lock=>true)
    logger.info("JOB CREATED WITH ID #{objSearch.id}")
    return objSearch.id
  end
  
  def self.retrieve_metadata(id, max, temps, infos_user)
    begin
      logger.debug("[job_queue][retrieve_metadata] : #{temps}")
      objJob = JobQueue.getJobInTemps(id, temps)
      if (objJob.nil?)
        return nil
      end
      cle = "#{objJob.records_id}"
      
      if CACHE_ACTIVATE 
        objRec = CACHE.get(cle)
        logger.info("[job_queue][retrieve_metadata] testing cache objerec #{objRec.class}")
        return objRec
      else
        objRecords = CachedRecord.find(objJob.records_id)
      end
      logger.debug("[job_queue][retrieve_metadata] for id #{id}")
      logger.debug("[job_queue][retrieve_metadata] ObjRecords class #{ObjRecords.class}")
      return nil if objRecords == nil
      return objRecords
    rescue => e
      logger.error("[job_queue][retrieve_metadata] error for id #{id} : #{e.message}")
      return nil
    end
  end
  
  def self.getJobInTemps(id, temps = nil)
    if (id.nil?)
      logger.error("[JobQueue][getJobInTemps] id is nil")
      return nil
    end
    
    objJob  = JobQueue.find(id)
    logger.debug("[job_queue][getJobInTemps] status : #{objJob.status} #{objJob.timestamp.to_f} > #{temps.to_f} = #{(objJob.timestamp.to_f > temps.to_f)}")
    # ignore when is superior
    if (!temps.blank? and objJob.timestamp.to_f > temps.to_f)
      logger.error("[JobQueue][getJobInTemps] temps is blank or superier")
      return nil
    else
      return objJob
    end
  end
  
  @@requete = "select c.alt_name as name, j.hits as hits, j.total_hits as total_hits, c.vendor_url as url, c.id as id, j.status status, j.id as job_id from collections c, job_queues j where c.id = j.collection_id and j.id in ("
  @@requete2 =") order by total_hits desc"
  
  # return array of hash order by total hits with ids job parameter
  # res[0].name = "collection" res[0].hits = 100
  def self.total_hits_by_jobs(ids_job)
    
    _result = Array.new()
    
    begin
      
      _i = 0
      _ids = ""
      ids_job.each { |job| 
        _ids += "#{job}"
        _i += 1
        
        if (_i < ids_job.length)
          _ids += ","
        end
      }
      
      logger.debug("jobs : #{_ids}")
      
      _sql = @@requete + _ids + @@requete2
      logger.debug("[job_queue][total_hits_by_jobs] Request : #{_sql}")
      _res = find_by_sql(_sql)
      if !_res.nil?
        _res.each { |row|
          _tab = Hash.new()
          _tab[:target_name] = row.name
          _tab[:hits] = row.hits
          _tab[:total_hits] = row.total_hits
          _tab[:url] = row.url
          _tab[:id] = row.id
          _tab[:status] = row.status
          _tab[:job_id] = row.job_id
          _result << _tab
        }
      end
    rescue => e
      logger.error("[total_hits_by_jobs] request : #{_sql}")
      logger.error("[total_hits_by_jobs] error : #{e.message}")
      logger.error("[total_hits_by_jobs] error : #{e.backtrace.join('\n')}")
      raise e
    end
    
    logger.debug("[total_hits_by_jobs] resultat: " + _result.inspect)
    
    return _result
  end
end
