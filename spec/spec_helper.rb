# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'database_cleaner'
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
# ## Mock Framework
#
# If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
#
# config.mock_with :mocha
# config.mock_with :flexmock
# config.mock_with :rr

# Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  
  # Test database cleaning strategy
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end

def setup_search
  st = Factory(:search_tab)
  Factory(:search_tab_subject, :search_tab=>st)
  Factory(:search_tab_filter, :search_tab=>st)
  Factory(:search_collection_group, :search_tab=>st)
  s = SearchTabSubject.new
  tree = s.CreateSubMenuTree
  
  
  filter_tab = SearchTabFilter.load_filter(st.id)
  linkMenu = SearchTab.load_menu
  groups_tab = SearchTab.load_groups(st.id)
  
  assign(:filter_tab, filter_tab)
  assign(:groups_tab, groups_tab)
  assign(:linkMenu, linkMenu)
  assign(:TreeObject, tree)
end

def factory_tabs
  st = Factory(:search_tab)
  st2 = Factory(:search_tab, :label =>"testRRR")
  st3 = Factory(:search_tab, :label =>"test111")
  sts = Factory(:search_tab_subject, :search_tab=>st)
  stf = Factory(:search_tab_filter, :search_tab=>st)
  return st.id
end

def authenticate_admin
  user = Factory(:admin)
  session[:user] = user
  session[:user_id] = user.id
end

# Some test cases require no transaction
def without_transactional_fixtures(&block)
  self.use_transactional_fixtures = false
  before(:all) do
    DatabaseCleaner.strategy = :truncation
  end

  yield
  
  after(:all) do
    DatabaseCleaner.strategy = :transaction
  end
end
