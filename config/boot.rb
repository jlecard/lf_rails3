require 'rubygems'

RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile',__FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'yaml'
YAML::ENGINE.yamler = 'syck'
