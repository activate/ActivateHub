namespace :sources do
  task 'import:all', [:site] => :tenantized_environment do |t,args|
    site = ActiveRecord::Base.current_site
    Source.enabled.each do |source|
      new_args = [site.domain, source.id]
      Rake::Task['sources:import'].tap(&:reenable).invoke(*new_args)
    end
  end

  task :import, [:site,:source_id] => :tenantized_environment do |t,args|
    unless source = Source.find(args[:source_id])
      raise "could not find source with id '#{args[:source_id]}'"
    end

    unless source.enabled?
      raise "source is currently flagged as disabled"
    end

    title = "#{source.name} (id: #{source.id}):"
    puts '='*76, title, '-'*title.length

    begin
      raise ActiveRecord::RecordInvalid if source.invalid?
      importer = SourceImporter.new(source)
      importer.import!

      puts importer.summary
      puts

    rescue => e
      # Could have more robust error handling here
      puts "#{e.class.name}: #{e.message}:", e.backtrace
      puts
    end

    CacheObserver.expire_all
  end

  task :tenantized_environment, [:site] => :environment do |t,args|
    unless site = Site.find_by_domain!(args[:site])
      raise "could not find site with path '#{args[:site]}'"
    end

    ActiveRecord::Base.current_site = site
  end

end
