class SearchClassGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def copy_search_class_file
    template "search_class.rb", "app/models/custom_connectors/#{file_name}_search_class.rb"
#    template "search_class_spec.rb", "spec/models/connectors/#{file_name}_spec.rb"
    
  end
end
