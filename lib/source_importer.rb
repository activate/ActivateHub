class SourceImporter
  attr_reader :source, :range_start
  attr_reader :abstract_events

  def initialize(source, options = {})
    options ||= {}

    @source = source
    @range_start = options[:range_start] || (Time.zone.now + 1.hour)

    @abstract_events = []
    @abstract_locations = []
  end

  def original_events
    source.events.where('start_time >= ?', range_start)
  end

  def fetch_upstream
    @abstract_events = SourceParser.to_abstract_events(:url => source.url)
    @abstract_events.reject! {|ae| ae.start_time < range_start }

    true
  end

end
