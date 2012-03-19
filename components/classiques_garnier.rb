require 'rubygems'
require 'marc'
require 'net/http'

class ClassiquesGarnier
  
  FILES = ["ColCorpusDictionnaires", "ColGodefroy", "ColLaCurne","ColHuguet",
          "ColDic01", "ColAcademie2","ColClm","ColClf","ColOceanIndien",
          "ColBdl","ColGarnier","ColGarnier_rcm"]
  
  def self.download_marc_files(download_dir, proxy_host, proxy_port, logger)
    url = 'www.classiques-garnier.com'  
    begin
      if !proxy_host.nil?
        proxy_host = proxy_host.gsub(/http:\/\//,"")
        logger.info("[ClassiquesGarnier] [download_marc_files] using proxy #{proxy_host}:#{proxy_port}")
        FILES.each do |collection_name|
          Net::HTTP.Proxy(proxy_host, proxy_port).start(url) do |http|
            resp = http.get("/public/index.php?module=Services&action=MarcRecords&downloadInfo=mrc_#{collection_name}")
            open("/#{download_dir}/#{collection_name}.mrc", "wb") do |file|
              file.write(resp.body)
            end
          end
        end
      else
        FILES.each do |collection_name|
          Net::HTTP.start(url) do |http|
            resp = http.get("/public/index.php?module=Services&action=MarcRecords&downloadInfo=mrc_#{collection_name}")
            open("/#{download_dir}/#{collection_name}.mrc", "wb") do |file|
              file.write(resp.body)
            end
          end
        end
      end
    rescue Exception => e
      if !logger.nil?
        logger.error("[ClassiquesGarnier] [download_marc_files] #{e.message}") 
        logger.debug(e.backtrace.join("\n"))
      else
        puts e.message  
      end
    end
  end
  
  # returns an array of MARC::Reader objects
  def self.read_marc_files(files_dir, logger)
    readers = Array.new
    begin
      Dir.glob("#{files_dir}/*.mrc") do |entry|
        begin
          logger.info("[ClassiquesGarnier][read_marc_files] input file : #{entry}")
          outfile = "#{entry.gsub('.mrc','')}_utf8.xml"
          logger.info("[ClassiquesGarnier][read_marc_files] output file : #{outfile}") 
          #system("/usr/bin/yaz-marcdump -f UTF8 -l 9=97  -o marc -t UTF-8 #{entry}>#{outfile}")
          system("java -cp #{RAILS_ROOT}/lib/marc4j.jar:#{RAILS_ROOT}/lib/normlizer.jar org.marc4j.util.MarcXmlDriver -normalize -encoding UTF8 -out #{outfile} #{entry}")
          reader = MARC::XMLReader.new(outfile)
          readers.push(reader) unless reader.nil?
        rescue Exception => e
          logger.error("[ClassiquesGarnier] [read_marc_files - create marc reader]: #{e.message}") 
          logger.error(e.backtrace.join("\n"))
          next
        end
      end
    rescue Exception => e
      if !logger.nil?
        logger.error("[ClassiquesGarnier] [read_marc_files - Dir.glob]: #{e.message}") 
        logger.debug(e.backtrace.join("\n"))
      else
        puts e.message
      end
    end
    return readers
  end
  
  def self.clear_downloaded_files(files_dir, logger)
    begin
      Dir.for_each(files_dir) do |file_name|
        begin
          logger.info("[ClassiquesGarnier][clear_marc_files] file : #{file_name}")
          next if file_name == "." or file_name == ".."
          FileUtils.rm(file_name)
        rescue Exception => e
          logger.error("[ClassiquesGarnier] [clear_marc_files]: #{e.message}") 
          logger.error(e.backtrace.join("\n"))
          next
        end
      end
    rescue Exception => e
      if !logger.nil?
        logger.error("[ClassiquesGarnier] [read_marc_files - Dir.glob]: #{e.message}") 
        logger.debug(e.backtrace.join("\n"))
      else
        puts e.message
      end
    end
    return readers
  end
end
