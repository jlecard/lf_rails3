require File.expand_path('../boot', __FILE__)
require 'rails/all'



if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
# If you want your assets lazily compiled in production, use this line
# Bundler.require(:default, :assets, Rails.env)
end

module LfRails3
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "UTF-8"
    #config.threadsafe!
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.i18n.default_locale = :fr

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    config.autoload_paths  += %W(#{Rails.root}/app/models/custom_connectors)
    

    class CustomLogger < Logger
      def format_message(severity, timestamp, progname, msg)
        "#{timestamp.to_formatted_s(:db)} #{severity} #{progname} #{msg}\n"
      end
    end
    require File.join(File.dirname(__FILE__), 'boot')
     if ENV['ENV_HARVESTING'] == 'true'
       logfile = "#{Rails.root}/log/harvesting_log.txt"
     elsif ENV['ENV_STATS'] == 'true'
       logfile = "#{Rails.root}/log/stats_log.txt"
     else
       logfile = "#{Rails.root}/log/#{ENV['RAILS_ENV']}.log"
     end
    logger = CustomLogger.new(logfile, 20, 1048576)
    config.logger = logger
    config.active_record.logger = logger
    #config.active_record.logger.level = Logger::WARN
    config.log_level = :debug

  end
end
