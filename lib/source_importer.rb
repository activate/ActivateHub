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
  end

end
