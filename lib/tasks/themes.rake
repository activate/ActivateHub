# copy our theme data at the same time we do the asset precompile,
# hopefully this will get triggered automatically on a heroku deploy
Rake::Task['assets:precompile'].enhance do
  # Remove cache first because otherwise create_cache fails if destination
  # files already exist (e.g. if create_cache is run twice)
  Rake::Task['themes:remove_cache'].invoke

  Rake::Task['themes:create_cache'].invoke
end
