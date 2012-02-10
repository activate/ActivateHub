desc "Compile less files"
task :less do
  verbose do
    sh "lessc themes/activate/stylesheets/site.less > themes/activate/stylesheets/site.css"
  end
end
