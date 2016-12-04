# Enable traversing up the locale hierarchy until we find a match,
# specifically: en-x-foo-bar -> en-x-foo -> en (not translation path)
Rails.application.config.i18n.fallbacks = true

# Include subdirectories when searching for locales
i18n_path = Rails.root.join('config', 'locales', '**', '*.{rb,yml}')
Rails.application.config.i18n.load_path += Dir[i18n_path]
