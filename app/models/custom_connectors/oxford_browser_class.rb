require 'rubygems'
require 'mechanize'

class OxfordgenericBrowserClass
  attr_reader :result_count, :result_list, :total
  
  def initialize(url=nil, logger=nil)
    @logger = logger
    @result_list = Array.new
    @url = url
  end
  
  def search(keyword, max)
    cookie = nil
    a = Mechanize.new do |agent|
      agent.set_proxy("spxy.bpi.fr","3128")
      agent.keep_alive = true
    end
    begin
      a.get(@url) do |page|
        search_form = page.forms[1]
        @keyword = keyword.gsub(/\s/,"+")
        @logger.debug("[OxfordBrowser][cookies] #{a.cookie_jar.inspect}")
        @cookies = a.cookie_jar
        search_form.field_with(:name => 'q').value = @keyword
        search_form.checkboxes.each do |check_box|
          check_box.checked=true
        end
        search_result = search_form.submit(search_form.button_with(:value=>/search/))
        @result_count = count(search_result)
        parse_results(search_result, max)
        more(search_result, max) if max > 25
      end
    rescue Net::HTTPForbidden => e
      @logger.error(e.message)
      @logger.debug("[OxfordBrowser][search] #{e.backtrace.join("\n")}")
    rescue Mechanize::ResponseCodeError => e
      @logger.error(e.message)
      @logger.debug("[OxfordBrowser][search] #{e.backtrace.join("\n")}")
    end
  end
  
  def more(result_page, max)
    num_pages = @result_count/25
    current_page = 2
    while current_page <= num_pages do
      result_page = result_page.link_with(:text =>/Next page/).click
      current_page += 1
      parse_results(result_page, max)
    end
  end
  
  def parse_results(result_page, max)
    @total = 0
    result_page.links_with(:href => /article\//).each do |link|
      text = UtilFormat.html_encode(link.text)
      desc = UtilFormat.html_encode(link.node.parent.text)
      short_desc = "#{desc[0..100]}..."
      match = desc.match(/\((.+?)\)/)
      subject = link.text
      url_link = "#{@url}/subscriber/#{link.href}"
      @logger.debug("[OxfordBrowser][linkhref] #{link.href}")
      @result_list.push({"text"=> text, "link" => url_link, "description" => desc, "short_desc" => short_desc, "subject"=>subject})
      @logger.debug("OxfordBrowserClass => Link = #{link}")
      @total += 1
      return if @total > max
    end
  end
  
  :private
  def count(search_page)
    regex = /returned (\d+) results/
    match = search_page.body.match(regex)
    return match[1].to_i if match
  end
  
end
