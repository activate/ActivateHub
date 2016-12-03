# If you are running a development environment and need to disable any
# optional gems or add additional tools, see doc/examples/Gemfile.local

source 'https://rubygems.org'

# FIXME: added Aug 5, 2012 -- this may be out of date
unless defined?($BUNDLER_INTERPRETER_CHECKED)
  if defined?(JRUBY_VERSION)
    puts "WARNING: JRuby cannot run Calagator. Its version of Nokogiri is incompatible with 'loofah', 'mofo' and other things. Although basic things like running the console and starting the server work, you'll run into problems as soon as you try to add/edit records or import hCalendar events."
    $JRUBY_WARNED = true
  end
  $BUNDLER_INTERPRETER_CHECKED = true
end

#---[ Database Adapter ]----------------------------------------------------

# custom Gemfile override, then env var, falling back to sqlite3
case defined?(DB_ADAPTER) ? DB_ADAPTER : ENV['DB_ADAPTER'] || 'sqlite3'
  when 'custom'     then # will load gems manually
  when 'postgresql' then # will always get installed, see below
  when 'mysql'      then gem 'mysql2'
  when 'sqlite3'    then gem 'sqlite3'
  else raise "unknown database adapter: #{ENV['DB_ADAPTER']}"
end

# really want 'pg' (postgresql) to stay in Gemfile.lock, for production, so
# will only allow override if different lock file (i.e. Gemfile.local.lock)
gem 'pg' unless defined?(DB_ADAPTER) && DB_ADAPTER != 'postgresql'

#---[ Core Gems ]-----------------------------------------------------------

gem 'thin'

# Run-time dependencies
gem 'rails', '~> 5.0.0'
gem 'rails_autolink'
gem 'nokogiri'
gem 'columnize'
gem 'rdoc', :require => false
gem 'geokit'
gem 'htmlentities'
gem 'paper_trail'
gem 'ri_cal'
gem 'rubyzip'
gem 'kaminari'
gem 'httparty'
gem 'loofah'
gem 'loofah-activerecord'
gem 'bluecloth'
gem 'formtastic'
gem 'acts-as-taggable-on'
gem 'jquery-rails'
gem 'progress_bar'
gem 'exception_notification'
gem 'rails3-jquery-autocomplete'
gem 'haml'
gem 'devise'
gem 'dalli'
gem 'cache_digests'
gem 'font-awesome-rails'
gem 'jquery-ui-rails'
gem 'responders'
gem 'activemodel-serializers-xml'

# Main gem does not yet have rails 5 support, using forked copy from PR:
# https://github.com/fusion94/paper_trail_manager/pull/31
gem 'paper_trail_manager',
  git: 'https://github.com/kwstannard/paper_trail_manager.git',
  branch: 'rails5'

platform :jruby do
  gem 'activerecord-jdbc-adapter'
  gem 'jruby-openssl'
  gem 'jruby-rack'
  gem 'warbler'

  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3'
end

platform :rbx do
  gem "rubysl"
  gem "racc"
end

# Some dependencies are only needed for test and development environments. On
# production servers, you can skip their installation by running:
#   bundle install --without development:test
group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'test-unit'
  gem 'faker' # Used by db/seeds.rb
  gem 'spork'

# # Do not install these interactive libraries onto the continuous integration server.
# unless ENV['CI'] || ENV['TRAVIS']
#   # Deployment
#   gem 'capistrano', '2.12.0'
#   gem 'capistrano-ext', '1.2.1'
# end
end

group :test do
  gem 'webrat'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-collection_matchers'
  gem 'capybara'
  gem 'timecop'
  gem 'rails-controller-testing'

  # Main gem does not yet have rails 5 support, using forked copy from PR:
  # https://github.com/thoughtbot/shoulda-matchers/pull/965
  gem 'shoulda-matchers',
    git: 'https://github.com/bsodmike/shoulda-matchers',
    branch: 'fix/rails5_issue_913'
end

group :development do
  gem 'spring'
  gem 'web-console'

  # Better Errors (interactive web debugging)
  gem 'better_errors'
  gem 'binding_of_caller'
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails', require: false
gem 'coffee-rails', require: false

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby, require: false

# Minify assets.  Requires a javascript runtime, such as 'therubyracer'
# above. You will also need to set 'config.assets.js_compressor' to ':uglifier'
# in config/environments/production.rb
gem 'uglifier', require: false

# Some dependencies are activated through server settings.
require "#{File.dirname(__FILE__)}/lib/secrets_reader"
secrets = SecretsReader.read(:silent => true)
case secrets.search_engine
when 'sunspot'
  gem 'sunspot_rails'
  gem 'sunspot_solr'
end
