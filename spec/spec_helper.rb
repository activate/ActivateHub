require 'rubygems'

# Calagator:
ENV['RAILS_ENV'] = 'test' if ENV['RAILS_ENV'].to_s.empty? || ENV['RAILS_ENV'] == 'development'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Automatically ensure test schema is up to date with development
ActiveRecord::Migration.maintain_test_schema!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Calagator: Load this project's custom spec extensions:
require File.expand_path(File.dirname(__FILE__) + '/spec_helper_extensions.rb')

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Filter out gems from backtraces
  config.backtrace_exclusion_patterns << /vendor\//
  config.backtrace_exclusion_patterns << /lib\/rspec\/rails/
  config.backtrace_exclusion_patterns << /gems\//

  config.use_transactional_fixtures = true

  # Allows us to use create(:user) instead of FactoryGirl.create :user
  config.include FactoryGirl::Syntax::Methods

  config.include Shoulda::Matchers::ActiveModel, type: :model
  config.include Shoulda::Matchers::ActiveRecord, type: :model

  # Makes warden available in tests, provides :sign_in and :sign_out
  config.include Devise::Test::ControllerHelpers, :type => :controller
  config.include Devise::Test::IntegrationHelpers, :type => :request

  # Some of the controller specs are using capybara-based matchers
  config.include Capybara::RSpecMatchers, :type => :controller

  # custom helpers and mixins, see spec/support/*
  config.include ControllerHelper, :type => :controller
  config.include AuthTestHelpers, :type => :controller

  # Database cleaner
  config.before(:suite) do
    # use a fixed time so tests and fixtures can make assumptions
    # about future events and not worry about changes in seconds, etc
    Timecop.travel(Time.zone.parse('2013-03-22 14:05:27'))
    Timecop.safe_mode = true
  end

  config.before(:each) do
    # data is tenantized by site, so we need to ensure a site exists for
    # all tests and that it matches the request.domain used for controller
    # and functional tests.
    ENV['TEST_REQ_HOST'] = 'activate.test'
    Site.create(
      :name     => 'Test Site',
      :domain   => ENV['TEST_REQ_HOST'],
      :timezone => 'Pacific Time (US & Canada)',
      :locale   => 'en',
    ).use!
  end
end
