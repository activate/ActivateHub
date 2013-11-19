# If you are running a development environment and need to disable any
# optional gems or add additional tools, see doc/examples/Gemfile.local

source 'https://rubygems.org'

unless ENV['IGNORE_RUBY_VER']
  # ensures everybody has same version of ruby this app uses in production.
  # heroku requires ruby version on own line (greps for version, not evals)
  ruby '1.9.3'
end

# FIXME: added Aug 5, 2012 -- this may be out of date
unless defined?($BUNDLER_INTERPRETER_CHECKED)
  if defined?(JRUBY_VERSION)
    puts "WARNING: JRuby cannot run Calagator. Its version of Nokogiri is incompatible with 'loofah', 'mofo' and other things. Although basic things like running the console and starting the server work, you'll run into problems as soon as you try to add/edit records or import hCalendar events."
    $JRUBY_WARNED = true
  elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
    puts "WARNING: Rubinius cannot run Calagator. It's multibyte string handling is broken in ways that break 'loofah' and other libraries. You won't even be able to start the console because this is such a severe problem."
  end
  $BUNDLER_INTERPRETER_CHECKED = true
end

#---[ Database Adapter ]----------------------------------------------------

# custom Gemfile override, then env var, falling back to sqlite3
case defined?(DB_ADAPTER) ? DB_ADAPTER : ENV['DB_ADAPTER'] || 'sqlite3'
  when 'custom'     then # will load gems manually
  when 'postgresql' then # will always get installed, see below
  when 'mysql'      then gem 'mysql2', '~> 0.3.11'
  when 'sqlite3'    then gem 'sqlite3'
  else raise "unknown database adapter: #{ENV['DB_ADAPTER']}"
end

# really want 'pg' (postgresql) to stay in Gemfile.lock, for production, so
# will only allow override if different lock file (i.e. Gemfile.local.lock)
gem 'pg' unless defined?(DB_ADAPTER) && DB_ADAPTER != 'postgresql'

#---[ Core Gems ]-----------------------------------------------------------

gem 'thin', '~> 1.5.1'

# Run-time dependencies
gem 'rails', '3.2.14'
gem 'rails_autolink', '1.1.3'
gem 'nokogiri', '1.5.10'
gem 'columnize', '0.3.6'
gem 'rdoc', '3.12.2', :require => false
gem 'geokit', '1.6.5'
gem 'htmlentities', '4.3.1'
gem 'paper_trail', '2.7.2'
gem 'ri_cal', '0.8.8'
gem 'rubyzip', '0.9.9', :require =>  'zip/zip'
gem 'kaminari', '~> 0.14'
gem 'httparty', '0.11.0'
gem 'multi_json' # Use whichever version 'httparty' wants, needed for our specs
gem 'loofah', '1.2.1'
# NOTE: 'loofah-activerecord' doesn't support Rails 3.2, so use my fork:
gem 'loofah-activerecord', :git => 'git://github.com/igal/loofah-activerecord.git', :branch => 'with_rails_3.1_and_3.2'
gem 'bluecloth', '2.2.0'
gem 'formtastic', '~> 2.2.1'
# validation_reflection 1.0.0 doesn't support Rails 3.2, so use unofficial patches:
gem 'validation_reflection', :git => 'git://github.com/ncri/validation_reflection.git', :ref => '60320e6beb088808fd625a8d958dbd0d2661d494'
gem 'acts-as-taggable-on', '2.4.1'
gem 'jquery-rails', '2.1'
gem 'progress_bar', '1.0.0'
gem 'exception_notification', '2.6.1'
gem 'rails3-jquery-autocomplete'
gem 'haml'
gem 'rails_admin', '0.4.8'
gem 'devise'
gem 'dalli'

gem 'paper_trail_manager', :git => 'https://github.com/dhedlund/paper_trail_manager.git', :ref => 'ba8e2dafb3d196950cdc62949b197a779e491779'
# gem 'paper_trail_manager', :path => '../paper_trail_manager'
# gem 'paper_trail_manager', '>= 0.2.0'

platform :jruby do
  gem 'activerecord-jdbc-adapter'
  gem 'jruby-openssl'
  gem 'jruby-rack'
  gem 'warbler'

  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3'
end

# Some dependencies are only needed for test and development environments. On
# production servers, you can skip their installation by running:
#   bundle install --without development:test
group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '2.11.0'
  gem 'webrat', '0.7.3'
  gem 'factory_girl_rails', '1.7.0' # 2.0 and above don't support Ruby 1.8.7 :(
  gem 'spork', '~> 0.9.2'
  gem 'database_cleaner', '~> 0.8.0'
  gem 'faker'
  gem 'shoulda-matchers', '~> 2.3.0'
  gem 'timecop', '~> 0.6.3'

  # Do not install these interactive libraries onto the continuous integration server.
  unless ENV['CI'] || ENV['TRAVIS']
    # Deployment
    gem 'capistrano', '2.12.0'
    gem 'capistrano-ext', '1.2.1'
  end
end

group :development do
  # Better Errors (interactive web debugging)
  gem 'better_errors'
  gem 'binding_of_caller'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  # Minify assets.  Requires a javascript runtime, such as 'therubyracer'
  # above. You will also need to set 'config.assets.compress' to true in
  # config/environments/production.rb
  gem 'uglifier', '>= 1.0.3'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  # gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  # Minify assets.  Requires a javascript runtime, such as 'therubyracer'
  # above. You will also need to set 'config.assets.compress' to true in
  # config/environments/production.rb
  gem 'uglifier', '>= 1.0.3'
end

# Some dependencies are activated through server settings.
require "#{File.dirname(__FILE__)}/lib/secrets_reader"
secrets = SecretsReader.read(:silent => true)
case secrets.search_engine
when 'sunspot'
  sunspot_version = '1.3.3'
  gem 'sunspot_rails', sunspot_version
  gem 'sunspot_solr',  sunspot_version
end
