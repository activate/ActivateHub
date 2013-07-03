<<<<<<< HEAD
ThemesForRails.config do |config|
  # Put static assets in Rails.root/themes/your-theme-name/{stylesheets,javascripts,images}
  config.assets_dir = ":root/themes/:name"
=======
Calagator::Application.configure do
  # add theme-specific asset directories to the asset pipeline
  theme_dir   = Rails.root.join('themes', ::THEME_NAME)
  asset_paths = Dir[theme_dir.join('{javascripts,stylesheets,images}')]
  config.assets.paths.prepend(*asset_paths)
>>>>>>> c83e59b... Full asset pipeline support for themes, remove themes_for_rails [THEME]

  # assets to include from theme when compiling assets (rake assets:precompile)
  config.assets.precompile += %w(theme.js theme.css)
  config.assets.precompile += ::SETTINGS.precompile_assets || []
end
