class EventsController < ApplicationController
  include SquashManyDuplicatesMixin # Provides squash_many_duplicates

  before_action :authenticate_user!, only: [:clone, :destroy, :edit]
  before_action :authenticate_admin, only: [:duplicates]

  def params
    @params ||= UntaintedParams.new(super).for(action_name)
  end

  # GET /events
  # GET /events.xml
  def index
    @start_date = date_or_default_for(:start)
    @end_date = date_or_default_for(:end)

    query = Event.non_duplicates.ordered_by_ui_field(params[:order]).includes(:venue)
    @events = query.within_dates(@start_date, @end_date)

    @events = @events.includes([:organization,:topics,:types])

    if params[:organization].present?
      organization_ids = params[:organization].to_s.split(',')
      @selected_organizations = Organization.where(:id => organization_ids)
      @events = @events.where(:organization_id => organization_ids)
    end

    if topic = params[:topic].presence
      @selected_topics = topic.split(',')
      @events = @events.joins(:topics).where('topics.name' => @selected_topics)
    end

    if type = params[:type].presence
      @selected_types = type.split(',')
      @events = @events.joins(:types).where('types.name' => @selected_types)
    end

    @topics = Topic.joins(:events).where("events.start_time > CURRENT_TIMESTAMP") \
      .select("DISTINCT topics.name AS name").reorder(:name)
    @types = Type.joins(:events).where("events.start_time > CURRENT_TIMESTAMP") \
      .select("DISTINCT types.name AS name").reorder(:name)

    @custom_content = true

    if params[:widget]
      render :layout => 'widget'
    else
      render_events(@events)
    end
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    begin
      @event = Event.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      return redirect_to events_path, :flash => {:failure => e.to_s}
    end

    if @event.duplicate?
      return redirect_to(event_path(@event.duplicate_of))
    end

    @page_title = @event.title

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @event.to_xml(:include => :venue) }
      format.json { render :json => @event.to_json(:include => :venue), :callback => params[:callback] }
      format.ics { ical_export([@event]) }
    end
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new(params[:event])
    @page_title = "Add an Event"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    @page_title = "Editing '#{@event.title}'"
  end

  # POST /events
  # POST /events.xml
  def create
    params[:event] ||= ActionController::Parameters.new({}).permit!
    params[:event][:type_ids] = create_missing_refs(params[:event][:type_ids], Type)
    params[:event][:topic_ids] = create_missing_refs(params[:event][:topic_ids], Topic)

    @event = Event.new(params[:event].to_h)
    @event.associate_with_venue(venue_ref(params[:event], params[:venue_name]))
    has_new_venue = @event.venue && @event.venue.new_record?

    @event.start_time = [ params[:start_date], params[:start_time] ]
    @event.end_time   = [ params[:end_date], params[:end_time] ]

    if evil_robot = params[:trap_field].present?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't create this event because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    if too_many_links = too_many_links?(@event)
      flash[:failure] = "We allow a maximum of 3 links in a description. You have too many links."
    end

    respond_to do |format|
      if !evil_robot && !too_many_links && params[:preview].nil? && @event.save
        flash[:success] = 'Your event was successfully created. '
        format.html {
          if has_new_venue && !params[:venue_name].blank?
            flash[:success] += " Please tell us more about where it's being held."
            redirect_to(edit_venue_url(@event.venue, :from_event => @event.id))
          else
            redirect_to( event_path(@event) )
          end
        }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        @event.valid? if params[:preview]
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])
    @event.associate_with_venue(venue_ref(params[:event], params[:venue_name]))
    has_new_venue = @event.venue && @event.venue.new_record?

    params[:event] ||= ActionController::Parameters.new({}).permit!
    params[:event][:type_ids] = create_missing_refs(params[:event][:type_ids], Type)
    params[:event][:topic_ids] = create_missing_refs(params[:event][:topic_ids], Topic)

    @event.start_time = [ params[:start_date], params[:start_time] ]
    @event.end_time   = [ params[:end_date], params[:end_time] ]
    @event.attributes = params[:event].to_h

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't update this event because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    if too_many_links = too_many_links?(@event)
      flash[:failure] = "We allow a maximum of 3 links in a description. You have too many links."
    end

    respond_to do |format|
      if !evil_robot && !too_many_links && params[:preview].nil? && @event.save
        flash[:success] = 'Event was successfully updated.'
        format.html {
          if has_new_venue && !params[:venue_name].blank?
            flash[:success] += "Please tell us more about where it's being held."
            redirect_to(edit_venue_url(@event.venue, :from_event => @event.id))
          else
            redirect_to( event_path(@event) )
          end
        }
        format.xml  { head :ok }
      else
        if params[:preview]
          @event.valid?
          @event.tags.reload # Reload the #tags association because its members may have been modified when #tag_list was set above.
        end
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url, :flash => {:success => "\"#{@event.title}\" has been deleted"}) }
      format.xml  { head :ok }
    end
  end

  # GET /events/duplicates
  def duplicates
    @type = params[:type]
    begin
      @grouped_events = Event.find_duplicates_by_type(@type)
    rescue ArgumentError => e
      @grouped_events = {}
      flash[:failure] = "#{e}"
    end

    @page_title = "Duplicate Event Squasher"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grouped_events }
    end
  end

  # Search!!!
  def search
    # TODO Refactor this method and move much of it to the record-managing
    # logic into a generalized Event::search method.

    @query = params[:query].presence
    @tag = params[:tag].presence
    @current = ["1", "true"].include?(params[:current])
    @order = params[:order].presence

    if @order && @order == "score" && @tag
      flash[:failure] = "You cannot sort tags by score"
      @order = nil
    end

    if !@query && !@tag
      flash[:failure] = "You must enter a search query"
      return redirect_to(root_path)
    end

    if @query && @tag
      # TODO make it possible to search by tag and query simultaneously
      flash[:failure] = "You can't search by tag and query at the same time"
      return redirect_to(root_path)
    elsif @query
      @grouped_events = Event.search_keywords_grouped_by_currentness(@query, :order => @order, :skip_old => @current)
    elsif @tag
      @grouped_events = Event.search_tag_grouped_by_currentness(@tag, :order => @order, :current => @current)
      if @grouped_events[:error]
        flash[:failure] = escape_once(@grouped_events[:error])
      end
    end

    # setting @events so that we can reuse the index atom builder
    @events = @grouped_events[:past] + @grouped_events[:current]

    @page_title = @tag ? "Events tagged with '#{@tag}'" : "Search Results for '#{@query}'"

    render_events(@events)
  end

  # Display a new event form pre-filled with the contents of an existing record.
  def clone
    @event = Event.find(params[:id]).to_clone
    @page_title = "Clone an existing Event"

    respond_to do |format|
      format.html {
        flash[:success] = "This is a new event cloned from an existing one. Please update the fields, like the time and description."
        render "new"
      }
      format.xml  { render :xml => @event }
    end
  end

  def widget_builder
    @topics = Topic.order(:name)
    @types = Type.order(:name)
    @organizations = Organization.order(:name)
  end


  protected

  # Checks if the description has too many links
  # which is probably spam
  def too_many_links?(event)
    # short-circuit restriction if orig description already had too many links
    return false if event.description_was.to_s.scan(/https?:\/\//i).size > 3

    event.description.to_s.scan(/https?:\/\//i).size > 3
  end

  # Export +events+ to an iCalendar file.
  def ical_export(events=nil)
    events = events || Event.future.non_duplicates
    render(:body => Event.to_ical(events, :url_helper => lambda{|event| event_url(event)}), :mime_type => 'text/calendar')
  end

  # Render +events+ for a particular format.
  def render_events(events)
    respond_to do |format|
      format.html # *.html.erb
      format.kml  # *.kml.erb
      format.ics  { ical_export(events.respond_to?(:future) ? events.future : events) }
      format.atom { render :template => 'events/index' }
      format.xml  { render :xml  => events.to_xml(:include => :venue) }
      format.json { render :json => events.to_json(:include => :venue), :callback => params[:callback] }
    end
  end

  # Return the default start date.
  def default_start_date
    Time.zone.today.beginning_of_week(:sunday)
  end

  # Return the default end date.
  def default_end_date
    (default_start_date + 2.months).end_of_month.end_of_week(:sunday)
  end

  # Return a date parsed from user arguments or a default date. The +kind+
  # is a value like :start, which refers to the `params[:date][+kind+]` value.
  # If there's an error, set an error message to flash.
  def date_or_default_for(kind)
    if params[:date].present?
      if params[:date].respond_to?(:has_key?)
        if params[:date].has_key?(kind)
          if params[:date][kind].present?
            begin
              return Date.parse(params[:date][kind])
            rescue ArgumentError => e
              append_flash :failure, "Can't filter by an invalid #{kind} date."
            end
          else
            append_flash :failure, "Can't filter by an empty #{kind} date."
          end
        else
          append_flash :failure, "Can't filter by a missing #{kind} date."
        end
      else
        append_flash :failure, "Can't filter by a malformed #{kind} date."
      end
    end
    return self.send("default_#{kind}_date")
  end

  class UntaintedParams < SimpleDelegator
    def for(action)
      respond_to?("for_#{action}") ? send("for_#{action}") : __getobj__
    end

    def for_clone
      permit(:id)
    end

    def for_create
      permit(*form_params, event: event_params)
    end

    def for_destroy
      permit(:id)
    end

    def for_duplicates
      permit(:type)
    end

    def for_edit
      permit(:id)
    end

    def for_index
      permit(*filter_params, *widget_params, :callback)
    end

    def for_new
      permit(event: event_params)
    end

    def for_search
      permit(:callback, :current, :order, :query, :tag)
    end

    def for_show
      permit(:callback, :id)
    end

    def for_update
      permit(*form_params, :id, event: event_params)
    end

    def for_widget_builder
      permit(*widget_params)
    end

    private def event_params
      [ :description, :organization_id, :tag_list, :title, :url, :venue_id,
        :venue_details, { type_ids: [], topic_ids: [] }
      ]
    end

    private def filter_params
      [:order, :topic, :type, date: [:end, :start]]
    end

    private def form_params
      [:end_date, :end_time, :preview, :start_date, :start_time, :trap_field, :venue_name]
    end

    private def widget_params
      [:organization, :topic, :types, :widget]
    end
  end

end
