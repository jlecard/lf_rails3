# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false

# Note: below are simple examples of email configuration settings.  See
# the Rails and ActiveMailer documentation for complete description of mail 
# options; the samples below might or might not fit your environment!
#
# For remote SMTP delivery
#config.action_mailer.delivery_method = :smtp
#config.action_mailer.perform_deliveries = true
#config.action_mailer.server_settings = {
#  :address => 'smtp.example.com',
#  :port    => 25,
#  :domain  => 'example.com'
#  }
#  
# For local delivery
#config.action_mailer.delivery_method = :sendmail
#config.action_mailer.perform_deliveries = true
  