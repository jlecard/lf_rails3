require 'rubygems'
require 'marc'
require 'net/http'

class PublieNet
  

  
  def self.download_marc_files(download_dir, proxy_host, proxy_port, logger)
    url = 'ws.immateriel.fr'
    begin
      if !proxy_host.nil?
          Net::HTTP.Proxy(proxy_host, proxy_port).start(url) do |http|
            resp = http.get("/fr/web_service/publisher_unimarc?company=publienet")
            open("/#{download_dir}/publienet.iso2709", "wb") do |file|
              file.write(resp.body)
            end
          end
      else
        FILES.each do |collection_name|
          Net::HTTP.start(url) do |http|
            resp = http.get("/fr/web_service/publisher_unimarc?company=publienet")
            open("/#{download_dir}/publienet.iso2709", "wb") do |file|
              file.write(resp.body)
            end
          end
        end
      end
    rescue Exception => e
      if !logger.nil?
        logger.error("[PublieNet] [download_marc_files] #{e.message}") 
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
      Dir.glob("#{files_dir}/*.iso2709") do |entry|
        begin
          reader = MARC::Reader.new(entry)
          readers.push(reader) unless reader.nil?
        rescue
          logger.error("[PublieNet] [read_marc_files - create marc reader]: #{e.message}") 
          logger.error(e.backtrace.join("\n"))
          next
        end
      end
    rescue Exception => e
      if !logger.nil?
        logger.error("[PublieNet] [read_marc_files - Dir.glob]: #{e.message}") 
        logger.debug(e.backtrace.join("\n"))
      else
        puts e.message
      end
    end
    return readers
  end
end
