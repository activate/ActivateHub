ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

$LOAD_PATH << File.expand_path('../vendor/gems/mofo-0.2.8/lib', __dir__)
