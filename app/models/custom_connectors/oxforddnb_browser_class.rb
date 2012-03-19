require 'rubygems'
require 'mechanize'

class OxforddnbBrowserClass
  attr_reader :result_count, :result_list, :url
  
  def initialize(url, logger)
    @logger = logger
    @result_list = Array.new
    @url = url
  end
  
  def search(keyword, max)
    a = Mechanize.new do |agent|
      agent.set_proxy("spxy.bpi.fr","3128")
      agent.keep_alive = false
    end
    
    begin
      a.get(@url) do |page|
        search_result = page.form_with(:name => 'quickSearchForm') do |search|
          search.field_with(:name => 'simpleName').value = keyword
          search.field_with(:name => 'searchTarget').options[1].select
          end.submit
          @result_count = count(search_result)
          result_page = search_result.frame_with(:name =>'main').click
          parse_results(result_page)
          get_more(a, 21, max) if max > 20
        end
      rescue Net::HTTPForbidden
        raise Net::HTTPForbidden, 'The resource is unavailable at this time'
      end
    end
    
    def get_more(agent, offset, max)
      num_pages = @result_count/20
      current_page = 2
      i = 0
      while offset < max and current_page < num_pages do
        agent.get('http://www.oxforddnb.com/search/refine/?docsStart=#{offset}') do |page|
          i += 1
          result_page = page.frame_with(:name =>'main').click
          parse_results(result_page)
          return if i > max
          current_page += 1
          offset += 20
        end
      end
    end
    
    def parse_results(result_page)
      result_page.links.each do |link|
        next if link.text[0..9]=="Click here" or link.text.match(/Oxford University/)
        desc = UtilFormat.html_encode(link.node.parent.text.strip.gsub(/[\n\s*]+/, " "))
        short_desc = "#{desc[0..100]}..."
        text = UtilFormat.html_encode(link.text.strip.gsub(/[\n\s*]+/, " "))
        subject = "#{text}"
        @result_list.push({"text" => text, "link" => link.href.gsub(/^\.\.\//,"#{@url}/"), "description" => desc, "short_desc" => short_desc, "subject"=>subject})
        @logger.debug("[OxfordDnBBrowserClass][parse_results] Hash: #{@result_list.last.inspect}")
      end
    end
    
  :private
    def count(search_page)
      result_page = search_page.frame_with(:name =>'main').click
      regex = /Your search returned <b>(\d+)<\/b> results/
      match = result_page.body.match(regex)
      return match[1].to_i if match
    end
    
  end
