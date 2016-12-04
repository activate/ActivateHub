require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Calagator
  class Application < Rails::Application
    #---[ Libraries ]-------------------------------------------------------

    # Gems are packaged in "Gemfile", run `bundle` to install them.

    # Standard libraries
    require 'fileutils'
    require 'net/http'
    require 'net/https'
    require 'open-uri'
    require 'set'
    require 'uri'

    # Bundled libraries
    $LOAD_PATH << Rails.root.join('vendor','gems','mofo-0.2.8','lib')
    require 'mofo'

    # Load from "/lib"
    $LOAD_PATH << Rails.root.join('lib')
    ### libraries
    require 'metaclass'
    require 'tag_model_extensions'
    ### monkeypatches
    require 'ext/nil_strip_html'
    require 'ext/time_get_zone'

    #---[ Plugins ]---------------------------------------------------------

    # Load these plugins first, or they won't work
    config.plugins = [
      :catch_cookie_exception,
      :exception_notification,
    ]

    #---[ Path -------------------------------------------------------------

    config.autoload_paths += [
      # App
      Rails.root.join('app','mixins'),
    ]

    config.eager_load_paths += [
      Rails.root.join('lib')
    ]

    #---[ Rails ]-----------------------------------------------------------

    config.action_controller.per_form_csrf_tokens = true

    # Deliver email using sendmail by default
    config.action_mailer.delivery_method = :sendmail
    config.action_mailer.sendmail_settings = { :arguments => '-i' }

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    #---[ Caching ]---------------------------------------------------------

    cache_path = Rails.root.join('tmp','cache',Rails.env)
    config.cache_store = :file_store, cache_path
    FileUtils.mkdir_p(cache_path)

    #---[ Asset Pipeline ]--------------------------------------------------
    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.assets.precompile += ["*.gif", "*.jpg", "*.png"]
    config.assets.precompile += [
      "forms.css", "forms.js",
      "mobile.css", "mobile.js",
      "theme.css", "theme.js",
      "widget.css", "widget.js",
      "jquery-ui.js",
    ]

    #---[ Locale / Translations ]-------------------------------------------

    # Enable traversing up the locale hierarchy until we find a match,
    # specifically: en-x-foo-bar -> en-x-foo -> en (not translation path)
    config.i18n.fallbacks = true

    # Include subdirectories when searching for locales
    i18n_path = Rails.root.join('config', 'locales', '**', '*.{rb,yml}')
    config.i18n.load_path += Dir[i18n_path]

    #---[ Secrets and settings ]--------------------------------------------

    config.before_initialize do
      # Read secrets
      require 'secrets_reader'
      ::SECRETS = SecretsReader.read

      # Set timezone for Rails
      config.time_zone = 'America/Los_Angeles' # FIXME: Make compatible w/ 'UTC'

      # Set cookie session
      config.session_store :cookie_store, :key => SECRETS.session_name || "calagator"
      config.secret_token = SECRETS.session_secret

      # Activate search engine
      require 'search_engine'
      SearchEngine.kind = Rails.env.test? ? "sql" : SECRETS.search_engine
    end

    # Set timezone for OS
    config.after_initialize do
      ENV['TZ'] = Time.zone.tzinfo.identifier
    end
  end
end
