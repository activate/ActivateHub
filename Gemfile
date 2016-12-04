source 'https://rubygems.org'

# Heroku requires ruby version on own line (reps for version, not evals)
unless %w(true yes 1).include?(ENV['IGNORE_RUBY_VER'])
  ruby '2.3.3'
end

gem 'rails', '~> 5.0.0'
gem 'puma'
gem 'pg'
gem 'dalli'

gem 'geokit' # For looking up lat/long coords of venues
gem 'paper_trail' # Change tracking of publicly editable content
gem 'acts-as-taggable-on'

# Calendar Fetching / Generating
gem 'httparty' # Used to fetch remote calendars
gem 'htmlentities' # Used by hcal parser
gem 'loofah' # Strip tags from descriptions when not wanting HTML
gem 'loofah-activerecord' # Mixes in ActiveRecord::Base#xss_foliate
gem 'nokogiri' # Used by mofo for microformat parsing

# Main gem is no longer maintained, the following forked seemed most active
gem 'ri_cal', # iCalendar support
  git: 'https://github.com/kjwierenga/ri_cal.git',
  branch: 'master'

# View / Rendering
gem 'haml'
gem 'formtastic'
gem 'bluecloth' # Allow markdown in event/venue description
gem 'rails_autolink' # Convert inline links into html links
gem 'kaminari' # Pagination

# Assets / Javascript
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Admin / Management
gem 'devise' # Authentication
gem 'rails_admin' # For creating new sites

# Main gem does not yet have rails 5 support, using forked copy from PR:
# https://github.com/fusion94/paper_trail_manager/pull/31
gem 'paper_trail_manager',
  git: 'https://github.com/kwstannard/paper_trail_manager.git',
  branch: 'rails5'

# Legacy, to support rails/rspec upgrades
gem 'activemodel-serializers-xml'
gem 'responders'

group :development do
  gem 'spring'
  gem 'web-console'
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-byebug', platform: :mri
  gem 'rspec-rails'
  gem 'faker' # Used by db/seeds.rb
end

group :test do
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'timecop'

  # Main gem does not yet have rails 5 support, using forked copy from PR:
  # https://github.com/thoughtbot/shoulda-matchers/pull/965
  gem 'shoulda-matchers',
    git: 'https://github.com/bsodmike/shoulda-matchers',
    branch: 'fix/rails5_issue_913'

  # Legacy, to support rails/rspec upgrades
  gem 'rspec-activemodel-mocks'
  gem 'rspec-collection_matchers'
  gem 'rails-controller-testing'
  gem 'rspec-its'
end


