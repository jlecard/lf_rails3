# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

if ENV['ENV_HARVESTING'] == 'true'
  logfile = "#{RAILS_ROOT}/log/harvesting_log.txt" 
elsif ENV['ENV_STATS'] == 'true'
  logfile = "#{RAILS_ROOT}/log/stats_log.txt" 
else
  logfile = "#{RAILS_ROOT}/log/#{ENV['RAILS_ENV']}.log"
end

Rails::VendorGemSourceIndex.silence_spec_warnings = true

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]
  
  # Add additional load paths for your own custom dirs
  #  config.threadsafe!
  config.gem('datanoise-actionwebservice', :lib => 'actionwebservice', :source => 'http://gems.github.com')
  
  #config.frameworks += [ :action_web_service]
  #config.action_web_service = Rails::OrderedOptions.new
  #config.load_paths += %W(
  #                      #{RAILS_ROOT}/app/apis
  #                      #{RAILS_ROOT}/app/models/custom_connectors
  #)
  config.load_paths += %W(
                          #{RAILS_ROOT}/app/models/custom_connectors
  )
 
  class CustomLogger < Logger
    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)} #{severity} #{progname} #{msg}\n" 
    end
  end
  
  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  config.logger = CustomLogger.new(logfile, 20, 1048576)
  #config.log_level = :debug
  config.log_level = :info
 
  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store
  #config.action_controller.session_store = :mem_cache_store
 
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql
 
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
 
  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
 
  # See Rails::Configuration for more options
  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_libraryfind_project_session',
    :secret      => 'ad6d4fa2f2a514bbe7f49b53d645489090d704e000b35f65ccaaca78996795bcbf4d34edec0afa3fbc6e971d84853c34556990c7664e7d385862104fe658f0ed'
  }
  
 config.gem 'composite_primary_keys'

 
end
# Must be set due to the spawning
#ActiveRecord::Base.allow_concurrency  = true
#ActiveRecord::Base.verification_timeout  = 590
if ENV['ENV_HARVESTING'] == 'true'
  ActiveRecord::Base.logger.level = Logger::INFO
elsif ENV['ENV_STATS'] == 'true'
  ActiveRecord::Base.logger.level = Logger::INFO
else
  ActiveRecord::Base.logger.level = Logger::INFO
end

#ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.
#    update(:database_manager => SmartSessionStore)
#SqlSessionStore.session_class = MysqlSession

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Configuration for email
ActionMailer::Base.delivery_method = :smtp
#config.action_mailer.perform_deliveries = true
yp = YAML::load_file(RAILS_ROOT + "/config/config.yml")

if !yp['SMTP_LOGIN'].blank?
  ActionMailer::Base.smtp_settings = {
    :address => yp['SMTP_ADRESS'].to_s,
    :port    => yp['SMTP_PORT'].to_i,
    :domain  => yp['SMTP_DOMAIN'].to_s,
    :authentication => :login,
    :user_name => yp['SMTP_LOGIN'].to_s,
    :password => yp['SMTP_PWD'].to_s  
  }
else
  ActionMailer::Base.smtp_settings = {
    :address => yp['SMTP_ADRESS'].to_s,
    :port    => yp['SMTP_PORT'].to_i,
    :domain  => yp['SMTP_DOMAIN'].to_s,
  }
end


#ActionMailer::Base.delivery_method = :sendmail
#ActionMailer::Base.sendmail_settings = {
#  :location => '/usr/sbin/sendmail',
#  :arguments => '-i -t'
#  }
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true
#ActionMailer::Base.default_charset = "iso-8859-1"

require 'composite_primary_keys'
