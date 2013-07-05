namespace :sources do
  task 'import:all', [:site] => :environment do |t,args|
    unless site = Site.find_by_domain(args[:site])
      raise "could not find site with domain '#{args[:site]}'"
    end

    ActiveRecord::Base.current_site = site

    #fresh_sources = Source.all.reject{ |s| s.events.future.length < 1 } # Could add some random element here to make sure we're not hitting all the sources
    fresh_sources = Source.all

    fresh_sources.each do |source|
      begin
        source.create_events!
      rescue => e
        # Could have more robust error handling here
        puts "[Source##{source.id}] #{e.message}"
      end
    end
  end
end
