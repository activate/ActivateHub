require 'task_helpers'
require 'source_importer'

namespace :sources do
  task 'import:all', [:site] => :tenantized_environment do |t,args|
    site = ActiveRecord::Base.current_site
    Source.enabled.each do |source|
      new_args = [site.domain, source.id]
      Rake::Task['sources:import'].tap(&:reenable).invoke(*new_args)
    end
  end

  task :import, [:site,:source_id,*(:argv0..:argv9)] => :tenantized_environment do |t,args|
    options = TaskHelpers.parse_var_args(args)

    dry_run = options.key?(:dry) ? options[:dry] : false

    sources = options[:source_id] == '*' \
      ? Source.enabled # wildcard, want all enabled sources
      : [Source.find(options[:source_id])]

    ActiveRecord::Base.transaction(:requires_new => true) do
      sources.each do |source|
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
      end

      raise ActiveRecord::Rollback if dry_run
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
