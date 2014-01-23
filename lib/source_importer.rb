class SourceImporter
  attr_reader :source, :range_start, :range_end
  attr_reader :abstract_events, :abstract_locations

  def initialize(source, options = {})
    options ||= {}

    @source = source
    @range_start = options[:range_start] || (Time.zone.now + 1.hour)
    @range_end = options[:range_end] || (Time.zone.now + 1.year)
  end

  def original_events
    source.events.where('start_time >= :start AND start_time < :end',
      :start => range_start, :end => range_end,
    )
  end

  def fetch_upstream
    @abstract_events = SourceParser.to_abstract_events(:url => source.url)

    # exclude events that fall outside our date range
    @abstract_events.reject! {|ae| ae.start_time < range_start }
    @abstract_events.reject! {|ae| ae.start_time >= range_end }

    @abstract_locations = @abstract_events.map(&:abstract_location).compact

    # ensure all abstract events and locations are associated with the source
    # FIXME: should eventually be done in source parser during Abstract* init
    @abstract_events.each {|ae| ae.source = source }
    @abstract_locations.each {|al| al.source = source }

    true
  end

  def import!
    # fetch upstream events if not tried yet
    fetch_upstream unless abstract_events

    abstract_locations.each do |abstract_location|
      begin
        abstract_location.import!
      rescue
        abstract_location.save_invalid!
      end
    end

    abstract_events.each do |abstract_event|
      begin
        abstract_event.import!
      rescue
        abstract_event.save_invalid!
      end
    end

    true
  end

  def summary
    re = (abstract_events||{}).group_by(&:result).symbolize_keys
    rv = (abstract_locations||{}).group_by(&:result).symbolize_keys
    re.default = rv.default = []

    summary = <<-SUMMARY.strip_heredoc
      Found #{abstract_events.size} event(s) starting from "#{range_start}".

      Events: #{"%+d" % re[:created].size}
        Invalid: #{re[:invalid].size}
        Created: #{re[:created].size}
        Updated: #{re[:updated].size}
        Unchanged: #{re[:unchanged].size}

      Venues: #{"%+d" % rv[:created].size}
        Invalid: #{rv[:invalid].size}
        Created: #{rv[:created].size}
        Updated: #{rv[:updated].size}
        Unchanged: #{rv[:unchanged].size}

    SUMMARY

    event_dump = [:invalid,:created,:updated,:unchanged].inject({}) do |h,state|
      h[state.to_s] = re[state].map do |abstract_event|
        if event = abstract_event.event
          # FIXME: timezone associated with event might not always be site's timezone
          desc = "#{event.start_time.to_date}: #{event.title} (id: #{event.id})"
          state == :invalid ? { desc => event.errors.full_messages } : desc
        end
      end
      h
    end

    venue_dump = [:invalid,:created,:updated,:unchanged].inject({}) do |h,state|
      h[state.to_s] = rv[state].map do |abstract_location|
        if venue = abstract_location.venue
          desc = "#{venue.title} (id: #{venue.id})"
          state == :invalid ? { desc => venue.errors.full_messages } : desc
        end
      end
      h
    end

    summary \
      + { 'events' => event_dump }.to_yaml(:line_width => -1) \
      + { 'venues' => venue_dump }.to_yaml(:line_width => -1)
  end
end
