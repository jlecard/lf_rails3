# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
#ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), 'application')
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
# if ENV['ENV_HARVESTING'] == 'true'
  # logfile = "#{RAILS_ROOT}/log/harvesting_log.txt" 
# elsif ENV['ENV_STATS'] == 'true'
  # logfile = "#{RAILS_ROOT}/log/stats_log.txt" 
# else
  # logfile = "#{RAILS_ROOT}/log/#{ENV['RAILS_ENV']}.log"
# end
# 
# # Must be set due to the spawning
# #ActiveRecord::Base.allow_concurrency  = true
# #ActiveRecord::Base.verification_timeout  = 590
# if ENV['ENV_HARVESTING'] == 'true'
  # config.logger.level = Logger::INFO
# elsif ENV['ENV_STATS'] == 'true'
  # config.logger.level = Logger::INFO
# else
  # config.logger.level = Logger::DEBUG
# end

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

#ActionMailer::Base.default_charset = "iso-8859-1"

require 'composite_primary_keys'
LfRails3::Application.initialize!

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
require "#{Rails.root}/config/initializers/lf"