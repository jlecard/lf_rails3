module SRU
  
  # base class for all SRU responses
  class Response
    require 'sru/xpath'
    include SRU::XPath
    
    
    attr_reader :doc
    attr_reader :parser
    attr_reader :namespaces
    
    def initialize(doc, parser = 'rexml')
      @doc				= doc;
      @parser			= parser;
      if parser != 'nokogiri'
        defs 				= @doc.root.namespaces.definitions;
      else
        defs        = @doc.root.namespaces
      end
      @namespace = Hash.new();
      
      # namespaces for use in xpath queries
      # this is technically more correct and is required for 
      # libxml to be able to parse the explain block.
      # @namespaces = {'zs'	=> 'http://www.loc.gov/standards/sru/', 'ns0' => 'http://explain.z3950.org/dtd/2.0/'}
      if parser != 'nokogiri'
        defs.each do |item|
          @namespace[item.prefix] = item.href;
        end
      else
        defs.each do |k, v|
          @namespace[k] = v;
        end
      end
    end
  end
end
