class MechanizeBrowser
  
  def initialize(url, logger=nil, proxy_host=nil, proxy_port=nil)
    @logger = logger
    @result_list = []
    @url = url
    @proxy_host = proxy_host.gsub(/http:\/\//,"")
    @proxy_port = proxy_port
  end

  def initialize_agent
    @agent = Mechanize.new do |agent|
      agent.set_proxy(@proxy_host,@proxy_port) if @proxy_host
      agent.keep_alive = false
    end
    @logger.debug("[MechanizeBrowser] agent = #{@agent.inspect}")
  end
  
end