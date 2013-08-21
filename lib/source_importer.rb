class SourceImporter
  attr_reader :source, :range_start
  attr_reader :abstract_events, :abstract_locations

  def initialize(source, options = {})
    options ||= {}

    @source = source
    @range_start = options[:range_start] || (Time.zone.now + 1.hour)
  end

  def original_events
    source.events.where('start_time >= ?', range_start)
  end

  def fetch_upstream
    @abstract_events = SourceParser.to_abstract_events(:url => source.url)
    @abstract_events.reject! {|ae| ae.start_time < range_start }

    @abstract_locations = @abstract_events.map(&:abstract_location).compact

    # ensure all abstract events and locations are associated with the source
    @abstract_events.each {|ae| ae.source = source }
    @abstract_locations.each {|al| al.source = source }

    true
  end

  def import!
    # fetch upstream events if not tried yet
    fetch_upstream unless abstract_events

    # separate out and save abstract events that fail validation checks
    invalid, valid = abstract_events.partition(&:invalid?)
    invalid.each(&:save_invalid!)

    true
  end

end
