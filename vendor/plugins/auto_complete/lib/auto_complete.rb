module AutoComplete      
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  #
  # Example:
  #
  #   # Controller
  #   class BlogController < ApplicationController
  #     auto_complete_for :post, :title
  #   end
  #
  #   # View
  #   <%= text_field_with_auto_complete :post, title %>
  #
  # By default, auto_complete_for limits the results to 10 entries,
  # and sorts by the given field.
  # 
  # auto_complete_for takes a third parameter, an options hash to
  # the find method used to search for the records:
  #
  #   auto_complete_for :post, :title, :limit => 15, :order => 'created_at DESC'
  #
  # For help on defining text input fields with autocompletion, 
  # see ActionView::Helpers::JavaScriptHelper.
  #
  # For more examples, see script.aculo.us:
  # * http://script.aculo.us/demos/ajax/autocompleter
  # * http://script.aculo.us/demos/ajax/autocompleter_customized
  module ClassMethods
    def auto_complete_for(object, method, options = {})
      logger = ActiveRecord::Base.logger
      order = ""
      
      define_method("auto_complete_for_#{object}_#{method}") do
        # dirty trick to avoid parameter name conflict
        # see controls.js
        # var entry = encodeURIComponent(this.options.paramName.substr(0, (this.options.paramName.length - 2)) + ']') + '=' +
        #      encodeURIComponent(this.getToken()); would return object[metho]=xxx instead of object[method]=xxx
        if params[object][method].nil? 
          l = method.to_s.length-2
          method_trick = method.to_s[0..l].to_sym
          params[object] = {method => params[object][method_trick]} unless params[object][method_trick].nil?  
        end
        conditions = "#{method} LIKE '#{params[object][method]}%'".to_s unless params[object][method].nil?
        # Ability to add customized conditions for autocompletion - 
        # Use auto_complete_for (object, method, {:conditions => myconditions} in the controller 
        logger.debug("AUTOCOMPLETE=> options[conditions]=#{options[:conditions]}")
        
        if options[:conditions].nil? or !method.nil?
          options[:conditions] = "#{conditions}"
        else
          options[:conditions] += " AND #{conditions}"
        end
        
        order = "#{method} ASC".to_s
        find_options = { 
          :conditions => options[:conditions],
          :order => order,
          :limit => 10 }.merge!(options)
        logger.debug(find_options.inspect)
        @items = object.to_s.camelize.constantize.find(:all, find_options)
        render :inline => "<%= auto_complete_result @items, '#{method}' %>"
      end
    end
  end
  
end