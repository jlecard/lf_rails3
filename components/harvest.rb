# set variable environment harvesting
# in order to log in special file
require File.dirname(__FILE__) + '/../config/boot'
ENV['ENV_HARVESTING'] = "true"
ENV['LIBRARYFIND_HOME'] = "#{File.expand_path('..')}" if ENV['LIBRARYFIND_HOME'] == nil
p ENV['LIBRARYFIND_HOME']
require "#{File.expand_path('.')}/common_harvester.rb"
# Common harvester that controls individual harvesters
#require "common_harvester"

# Registered harvesters
begin
  #require ENV['LIBRARY_FIND_HOME'] + '/components/profession_politique_harvester.rb'
  #require ENV['LIBRARY_FIND_HOME'] + '/components/ged_harvester'
  #require ENV['LIBRARY_FIND_HOME'] + '/components/portfolio_harvester'
  #require ENV['LIBRARY_FIND_HOME'] + '/components/oai_harvester'
  #p ENV['LIBRARY_FIND_HOME'] + '/components/classiques_garnier_harvester.rb'
  #require ENV['LIBRARY_FIND_HOME'] + '/components/classiques_garnier_harvester.rb'
  p "#{File.expand_path('.')} expanded"
  require "#{File.expand_path('.')}/classiques_garnier_harvester.rb"
rescue Exception => e
  p "error"
  p e.backtrace
  p e.message
end


begin
  if ENV['AMD64'] != 1
    require 'sys/proctable'
    include Sys
  end
rescue LoadError => e
  raise LoadError(e.message, "sys-proctable library must be installed. You may download it from http://rubyforge.org/frs/?group_id=610&release_id=40379")
end

#require ENV['LIBRARY_FIND_HOME'] + '/app/models/harvest_schedule'

class Harvester < CommonHarvester
  attr_accessor :diff
  def initialize
    super(ENV['RAILS_ENV'])
    @diff = true
  end
  # harvest every collection in the database
  def harvest_all_collections
    collections = Collection.find(:all, {:conditions=>"conn_type NOT IN ('z3950', 'sru','opensearch')"})
    collections.each do |collection|
      harvest_collection(collection.id)
    end
  end
  
  # harvest collection identified by collection_id
  def harvest_collection(collection_id)
    
    collection = Collection.find_by_id(collection_id)
    # Deal with class names to retrieve proper object class
    # Class names can be camelized : MyClassHarvester or
    # capitalized : MyclassHarvester
    
    if collection.conn_type != "connector"
      harvest_class = collection.conn_type.capitalize
    else
      harvest_class = collection.name.camelize
    end
    
    begin
      eval("#{harvest_class}Harvester")
    rescue Exception => e
      harvest_class = harvest_class.camelize
    end
    
    begin
      harvest_instance = eval("#{harvest_class}Harvester")
      instance = harvest_instance.new
      @logger.info("HARVEST: Harvesting using #{instance.class}")
      instance.harvest(collection.id, @diff)
    rescue => e
      @logger.error(e.message)
      @logger.error(e.backtrace.join("\n"))
      @logger.error("#{collection.name} (id=#{collection.id}) has not been harvested")
    end
    
  end
  
  def harvest_scheduled_collections(schedules)
    
    schedules.each do |schedule|
      harvest_collection(schedule.collection_id)
    end
  end
  
  # returns the number of processes containing the 
  # name of this file already running (and its pid is not the one currently running)
  def harvest_in_progress?
    # proctable don't exist for amd64
    if AMD64 == 1
      return -1
    end
    process_number = 0
    ProcTable.ps{|proc_struct|
      process_number += 1 if proc_struct.cmdline.match(/#{__FILE__}/) && proc_struct.pid != $$
    }
    return process_number
  end
  
  # Returns an Array of HarvestSchedules harvestable at the time the method is called 
  :private
  def schedules_to_harvest
    ftime = Time.now.strftime("%A-%H:%M").split("-")
    day = ftime[0]
    stime = ftime[1].split(":")[1]
    hour = ftime[1].split(":")[0]
    
    if (0..14).to_a.include?(stime.to_i)
      stime = "#{hour}:00"
    elsif (15..29).to_a.include?(stime.to_i)
      stime = "#{hour}:15"
    elsif (30..44).to_a.include?(stime.to_i)
      stime = "#{hour}:30"
    elsif (45..59).to_a.include?(stime.to_i)
      stime = "#{hour}:45"  
    end
    @logger.debug("[schedules_to_harvest] jour:#{day} heure:#{stime}")
    schedules = HarvestSchedule.find(:all,:conditions=>"DATE_FORMAT(time,'%H:%i')='#{stime}' AND day='#{day}'")
    return schedules
  end
end

# Main program loop
# usage : 
#   harvest.rb all => harvest all collections
#   harvest.rb 1 57 34 49 => harvest collections with the id given as parameters
#   harvest.rb (no args) => harvest the collections scheduled for harvesting
#   harvest.rb -full => harvest the collections scheduled for harvesting (no diff)
##if __FILE__ == $0
begin
  h = Harvester.new
  begin
    args = $*
    if args.include?("-full")
      h.diff = false
      $*.delete("-full")
    end
    if $*.empty?
      h.logger.debug("**** Start harvest cron ****")
      schedules = h.schedules_to_harvest
      
      if schedules.length > 0
        collection_names = ""
        schedules.collect{|x| collection_names += "#{x.collection.name}\n" unless x.collection.nil?}
        h.logger.info("Scheduled collections : #{collection_names}")
        if h.harvest_in_progress? < 3
          h.harvest_scheduled_collections(schedules)
          h.logger.info("**** Finish harvest schedules ****")
        else
          h.logger.debug("Harvest is already in progress... Skipping scheduled harvesting...")
        end
      else
        h.logger.debug("Nothing to harvest... Exiting")
      end
      
    elsif $*.include?('all')
      if h.harvest_in_progress? < 3
        h.logger.info("**** Start harvest all ****")
        h.harvest_all_collections
        h.logger.info("**** Finish harvest all ****")
      else
        h.logger.info("Harvest is already in progress... Skipping all collections harvesting")
      end
    elsif $*.size >= 1
      if h.harvest_in_progress? < 3
        h.logger.info("**** Start harvest manual ****")
        $*.each do |collection_id|
          raise ArgumentError.new("Argument #{collection_id} should be an integer") if !collection_id.match(/^\d+$/)
          h.harvest_collection(collection_id.to_i)
        end
        h.logger.info("**** Finish harvest collections ****")
      else
        h.logger.info("Harvest is already in progress... Skipping harvesting for collections #{$*.inspect}")
      end
    else
      raise ArgumentError.new("Wrong arguments: #{$*.inspect}")
    end
  rescue => e
    h.logger.error(e.message)
    h.logger.debug(e.backtrace.join("\n"))
    raise e
  end
rescue Exception => e
  puts(e.message, e.backtrace.join("\n"))
  exit 2
end
##end
