class Admin::EventsController < AdminController
  respond_to :html, :json

  include SquashManyDuplicatesMixin # provides squash_many_duplicates

  def index
    @events = Event.non_duplicates

    if params[:type] == 'missing_end_time'
      @events = @events.where('end_time is null or end_time = start_time')
        .order("start_time desc")
    elsif params[:type] == 'missing_topic'
      @events = @events
        .joins("LEFT JOIN events_topics ON (events_topics.event_id = events.id)") \
        .where("events_topics.event_id IS NULL")
        .order("start_time desc, end_time asc")
    elsif params[:type] == 'missing_type'
      @events = @events
        .joins("LEFT JOIN events_types ON (events_types.event_id = events.id)") \
        .where("events_types.event_id IS NULL")
        .order("start_time desc, end_time asc")
    end

    @events = @events.order(:title)

    respond_with [:admin, @events]
  end

  def duplicates
    @events = Event.non_duplicates
    @groupings = []

    if params[:type] == 'overlapping_venue_and_time'
      @events = @events.where('venue_id is not null')
      @events = @events.order('start_time desc, end_time asc')
      @events.group_by(&:venue_id).each do |venue_id,events|
        while event = events.shift
          matched = events.take_while {|e| e.end_time >= event.end_time }
          events -= matched # take_while doesn't remove from orig events list
          @groupings << [event, *matched] if matched.any?
        end
      end
    end

    @groupings.sort_by! {|event,_| -(event.start_time.to_i) }
    respond_with @groupings
  end

end
