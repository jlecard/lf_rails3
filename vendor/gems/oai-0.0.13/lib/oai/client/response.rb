module OAI
  class Response
    include OAI::XPath
    attr_reader :doc, :resumption_token
    
    def initialize(doc)
      @doc = doc
      @resumption_token = xpath(doc, './/resumptionToken')
      
      # throw an exception if there was an error
      error = xpath_first(doc, './/error')
      return unless error
      
      case parser_type(error)
        when 'rexml'
        message = error.text
        code = error.attributes['code']
        when 'nokogiri'
        message = error.content
        code = error.attributes['code']
        when 'libxml'
        message = error.content
        code = ""
        if defined?(error.property) == nil
          code = error.attributes['code']
        else
          begin
            code = error["code"]
          rescue
            code = error.property('code')
          end
        end
      end
      raise OAI::Exception.new(message, code)
    end
  end
end
