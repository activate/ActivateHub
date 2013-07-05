namespace :sources do
  task 'import:all', [:site] => :environment do |t,args|
    unless site = Site.find_by_domain(args[:site])
      raise "could not find site with domain '#{args[:site]}'"
    end

    ActiveRecord::Base.current_site = site

    Source.scoped.each do |source|
      title = "#{source.name} (id: #{source.id}):"
      puts '='*76, title, '-'*title.length

      begin
        raise ActiveRecord::RecordInvalid if source.invalid?
        result = reimport_source(source)
        puts reimport_summary(source, result)
        puts

      rescue => e
        # Could have more robust error handling here
        puts "#{e.class.name}: #{e.message}:", e.backtrace
        puts
      end
    end
  end

  def reimport_source(source, start_time = nil)
    # will only create/update/delete events at or after start_time
    start_time ||= Time.zone.now + 1.hour

    # list of events we expect source to return f no changes since last pull.
    orig_events = source.events.where('start_time >= ?', start_time)

    # unfiltered list of events pulled from the source
    # FIXME: it would be nice to identify and report on the parser used
    abstract_events = SourceParser.to_abstract_events(:url => source.url)
    events = abstract_events.map {|ae| Event.from_abstract_event(ae, source) }

    # ignore events that are older than start_time
    events.reject! {|e| e.start_time && e.start_time < start_time }

    # separate out events that fail basic validation checks (title, start_time, etc)
    valid_events, invalid_events = events.partition(&:valid?)

    created_events, existing_events = [], []
    created_venues, existing_venues, invalid_venues = [], [], []

    valid_events.each do |event|
      venue = event.venue
      if venue.new_record?
        if venue.save
          created_venues << venue
        else
          invalid_venues << venue
        end
      else
        # FIXME: do we know for certain venues can't get updated?
        existing_venues << venue
      end

      if event.new_record?
        # convert to local time, tz is discarded when event is saved
        # FIXME: is this really true? it should convert to utc in newer rails
        event.start_time.localtime
        event.end_time.localtime if event.end_time

        event.types = source.types
        event.topics = event.organization.topics

        if event.save
          created_events << event
        else
          invalid_events << event
        end

      else
        # FIXME: it's possible the event could still be updated, especially
        # once we better set up "almost matches" (esp. w/ description)

        # matches another event, find and track the one associated with
        # this source so we don't accidentally delete it later
        matching_events = [event, *event.duplicates]
        existing_events += matching_events.select {|e| e.source_id == source.id }
      end
    end

    # remove any events associated w/ source, not returned during this fetch
    removed_events = (orig_events - existing_events).each(&:destroy)

    # strip out duplicate venues created as part of this re-import
    all_venues = [] # keep track of venues we've seen so far
    all_venues += invalid_venues = invalid_venues.uniq
    all_venues += created_venues = (created_venues - all_venues).uniq
    all_venues += existing_venues = (existing_venues - all_venues).uniq

    {
      :start_time => start_time,
      :events => {
        :invalid  => invalid_events,
        :created  => created_events,
        :removed  => removed_events,
        :existing => existing_events,
        :total    => valid_events.count + invalid_events.count,
      },
      :venues => {
        :invalid  => invalid_venues.uniq,
        :created  => created_venues.uniq,
        :existing => existing_venues.uniq,
        :total    => all_venues.count,
      },
    }
  end

  def reimport_summary(source, result)
    re,rv = result[:events], result[:venues]

    # FIXME: need to include link to /organizations/:org_id/sources/:source_id

    summary = <<-SUMMARY.strip_heredoc
      Found #{re[:total]} event(s) starting from "#{result[:start_time]}".

      Events: #{"%+d" % (re[:created].count - re[:removed].count)}
        Invalid:  #{re[:invalid].count}
        Created:  #{re[:created].count}
        Removed:  #{re[:removed].count}
        Existing: #{re[:existing].count}

      Venues: #{"%+d" % rv[:created].count}
        Invalid:  #{rv[:invalid].count}
        Created:  #{rv[:created].count}
        Existing: #{rv[:existing].count}

    SUMMARY

    event_dump = [:invalid,:created,:removed,:existing].inject({}) do |h,state|
      h[state.to_s] = re[state].map do |event|
        # FIXME: timezone associated with event might not always be site's timezone
        desc = "#{event.start_time.to_date}: #{event.title} (id: #{event.id})"
        event.valid? ? desc : { desc => event.errors.full_messages }
      end
      h
    end

    venue_dump = [:invalid,:created,:existing].inject({}) do |h,state|
      h[state.to_s] = rv[state].map do |venue|
        desc = "#{venue.title} (id: #{venue.id})"
        venue.valid? ? desc : { desc => venue.errors.full_messages }
      end
      h
    end

    summary \
      + { 'events' => event_dump }.to_yaml \
      + { 'venues' => venue_dump }.to_yaml
  end

end
