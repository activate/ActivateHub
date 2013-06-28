# copy our theme data at the same time we do the asset precompile,
# hopefully this will get triggered automatically on a heroku deploy
Rake::Task['assets:precompile'].enhance do
  Rake::Task['themes:create_cache'].invoke
end
