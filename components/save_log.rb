
class SaveLog
  
  require 'ftools'
  require 'fileutils'
  require 'yaml'
  
  RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
  
  # set variable environment harvesting
  # in order to log in special file
  ENV['ENV_STATS'] = 'true'
  
  if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
  require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'
  
  db = YAML::load_file(ENV['LIBRARYFIND_HOME'] +"config/database.yml")
  yml = YAML::load_file(ENV['LIBRARYFIND_HOME'] +"config/config.yml")
  local_indexer = ""
  if (LIBRARYFIND_INDEXER.downcase == 'ferret')
    require 'ferret'
    include Ferret
    local_indexer = 'ferret'
  elsif (LIBRARYFIND_INDEXER.downcase == 'solr')
    require 'rubygems'
    require 'solr'
    local_indexer = 'solr'
  end 
  
  dbtype = ""
  for arg in ARGV
    puts arg
    if arg.downcase == 'development' || arg.downcase == 'production' || arg.downcase =='test'
      dbtype = arg
    end
  end
  
  if dbtype.blank? 
    dbtype = "development"
  end
  
  ActiveRecord::Base.establish_connection(
                                          :adapter  => db[dbtype]["adapter"],
  :host     => db[dbtype]["host"],
  :username => db[dbtype]["username"],
  :password => db[dbtype]["password"],
  :database => db[dbtype]["database"],
  :port     => db[dbtype]["port"]
  )
  
  logger = ActiveRecord::Base.logger
  
  if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
  require ENV['LIBRARYFIND_HOME'] + 'app/controllers/log_generic.rb'
  
  filelog = yml["LOG_FILE_LOCATION"] + yml["LOG_NAME_FILE"]
  filelogback = filelog + ".bck"
  
  if (File.exist?(filelog))
    FileUtils.cp(filelog, filelogback);
    system("cat /dev/null >#{filelog}")
    fd = File.open(filelogback,  File::RDONLY);
    
    begin
      while (line = fd.readline())
        line.chomp;
        if ((!line.blank?) && (!line.match(/^#/)))
          tab 			= line.split("$");
          className = tab[1];
          timeStamp = tab[0];
          tab.delete_at(0);
          tab.delete_at(0);
          # /!\ Security Exploit here with 'eval' be carefulllllllll !!!! /!\
          items = eval(tab.to_s());
          items[:created_at] = timeStamp;
          items[:updated_at] = timeStamp;
          
          logger.debug("[saveLog.rb] inspect Items : " + items.inspect);
          LogGeneric.add(className, items);
          logger.debug("className : " + className.to_s + " timeStamp : " + timeStamp.to_s + " Items : " + items.inspect);
        end
      end
    rescue EOFError
      fd.close();
      FileUtils.rm(filelogback, :force => true);
    end
  else
    logger.error("[saveLog.rb] Error on search file #{filelogback}");
  end
end


begin
  SaveLog.new
rescue => e
  puts "Error on statistic update : #{e.message}"
end
