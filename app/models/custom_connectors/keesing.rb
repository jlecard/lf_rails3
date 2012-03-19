require 'rubygems'
require 'mechanize'


class KeesingBrowserClass
  attr_reader :result_count, :result_list, :total
  
  def initialize(url=nil, logger=nil)
    @logger = logger
    @result_list = Array.new
    @url = url
  end
  
  def search(keyword, max)
    @logger.debug("[Keesing][search] url = #{@url}/search?kssp_search_phrase=#{keyword}")
    a = Mechanize.new do |agent|
      agent.set_proxy("spxy.bpi.fr","3128")
      agent.keep_alive = true
    end
    
    begin
      a.get("#{@url}/search?kssp_search_phrase=#{keyword}") do |page|
        @logger.debug("[Keesing][search] page = #{page}")
        @total = 0
        parse_results(page, max)
        get_more(page, max) if max > 10
      end
    rescue Net::HTTPForbidden => e
      @logger.error("[Keesing][search] Access refused #{e.message}")
      #raise e
    rescue Mechanize::ResponseCodeError => e
      @logger.error("[Keesing][search] Error code #{e.message}")
      #raise e
    rescue Exception => e
      @logger.error("[Keesing][search] Error #{e.message}")
    end
  end
  
  def get_more(result_page, max)
    while @total < max do
      res = result_page
      result_page = result_page.link_with(:text =>/Next/).click if !result_page.link_with(:text =>/Next/).nil? 
      if res != result_page
        parse_results(result_page, max)
      else
        @logger.debug("[Keesing][get_more] - same page #{res = result_page}")
        return
      end
    end
  end
  
  def parse_results(result_page, max)
    result_page.links_with(:href=>/kssp_a_id/).each do |link|
      short_desc = link.node.parent.text
      desc = link.node.parent.next_sibling.next_sibling.text
      date = format_date(link.node.parent.next_sibling.next_sibling.next_sibling.next_sibling.text)
      @logger.debug("[Keesing][parse_results] link => #{link.href}, description => #{desc}, date => #{date},short_desc=>#{short_desc}")
      @result_list.push({"link" => link.href, "description" => desc, "date" => date,"short_desc"=>short_desc})
      @total += 1
      @logger.debug("[Keesing][parse_results] total => #{@total}")
      return if @total >= max
    end
  end
  
  # returns a date in form yyyymm with sss yyyy as input
  def format_date(date_value)
    yyyy = date_value[4..7]
    case date_value[0..2].downcase
      when "jan"
      date_value = "#{yyyy}-01"
      when "feb"
      date_value = "#{yyyy}-02"
      when "mar"
      date_value = "#{yyyy}-03"
      when "apr"
      date_value = "#{yyyy}-04"
      when "may"
      date_value = "#{yyyy}-05"
      when "jun"
      date_value = "#{yyyy}-06"
      when "jul"
      date_value = "#{yyyy}-07"
      when "aug"
      date_value = "#{yyyy}-08"
      when "sept"
      date_value = "#{yyyy}-09"
      when "oct"  
      date_value = "#{yyyy}-10"
      when "nov"
      date_value = "#{yyyy}-11"
      when "dec"
      date_value = "#{yyyy}-12"
    end
    return date_value
  end
end