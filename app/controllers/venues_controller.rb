class VenuesController < ApplicationController
  include SquashManyDuplicatesMixin # Provides squash_many_duplicates

  before_action :authenticate_user!, only: [:clone, :destroy, :edit, :update]

  def params
    @params ||= UntaintedParams.new(super).for(action_name)
  end

  # GET /venues
  # GET /venues.xml
  def index
    scoped_venues = Venue.non_duplicates

    @types = Type.select("DISTINCT types.name AS name").reorder(:name)
    if type = params[:type].presence
      @selected_types = type.split(',')
      scoped_venues = scoped_venues.where(id: Event.joins(:types).where("types.id = ?", Type.find_by_name(type)).pluck(:venue_id))
    end

    # Pick a subset of venues (we want in_business by default)
    if params[:include_closed]
      scoped_venues = scoped_venues
    elsif params[:closed]
      scoped_venues = scoped_venues.out_of_business
    else
      scoped_venues = scoped_venues.in_business
    end

    # Support old ajax autocomplete parameter name
    params[:term] = params[:val] if params[:val]

    @tag = nil
    if params[:tag].present? # searching by tag
      @tag = params[:tag]
      @venues = scoped_venues.tagged_with(@tag)
    else
      scoped_venues = scoped_venues.with_public_wifi if params[:wifi]

      if params[:term].present? # for the ajax autocomplete widget
        conditions = ["title LIKE :query", {:query => "%#{params[:term]}%"}]
        @venues = scoped_venues.where(conditions).order('lower(title)')
      elsif params[:query].present?
        @venues = Venue.search(params[:query], :include_closed => params[:include_closed], :wifi => params[:wifi])
      else
        @venues = scoped_venues
      end
    end

    @most_active_venues = scoped_venues.where('events_count is not null').limit(10).order('events_count DESC')
    @newest_venues = scoped_venues.limit(10).order('created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml  => @venues || scoped_venues }
      format.json { render :json => @venues || scoped_venues, :callback => params[:callback] }
      format.js   { render :json => @venues || scoped_venues, :callback => params[:callback] }
      format.kml  { @venues ||= scoped_venues; render } # index.kml.erb
    end
  end

  # GET /venues/map
  def map
    @venues = Venue.non_duplicates.in_business
  end

  # GET /venues/1
  # GET /venues/1.xml
  def show
    begin
      @venue = Venue.includes(:source).find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to(venues_path)
    end

    return redirect_to(venue_url(@venue.duplicate_of)) if @venue.duplicate?

    @page_title = @venue.title

    respond_to do |format|
      format.html {
        @future_events = @venue.events.order("start_time ASC").future.non_duplicates.includes(:venue).limit(10)
        @past_events = @venue.events.order("start_time DESC").past.non_duplicates.includes(:venue).limit(10)
      }
      format.xml  { render :xml => @venue }
      format.json  { render :json => @venue, :callback => params[:callback] }
      format.ics  { ical_export(@venue) }
    end
  end

  # GET /venues/new
  # GET /venues/new.xml
  def new
    @venue = Venue.new
    @page_title = "Add a Venue"

    respond_to do |format|
      format.html { render :layout => !(params[:layout]=="false") }
      format.xml  { render :xml => @venue }
    end
  end

  # GET /venues/1/edit
  def edit
    @venue = Venue.find(params[:id])
    @page_title = "Editing '#{@venue.title}'"
  end

  # POST /venues
  # POST /venues.xml
  def create
    @venue = Venue.new(params[:venue])

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't create this venue because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && params[:preview].nil? && @venue.save
        flash[:success] = 'Venue was successfully created.'
        format.html { redirect_to( venue_path(@venue) ) }
        format.xml  { render :xml => @venue, :status => :created, :location => @venue }
      else
        @venue.geocode if params[:preview] && @venue.valid?
        format.html { render :action => "new" }
        format.xml  { render :xml => @venue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /venues/1
  # PUT /venues/1.xml
  def update
    params[:venue][:latitude] = params[:venue][:longitude] = nil if params[:venue][:force_geocoding]=="1" unless params[:venue].blank?
    @venue = Venue.find(params[:id])
    
    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't update this venue because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && params[:preview].nil? && @venue.update_attributes(params[:venue].to_h)
        flash[:success] = 'Venue was successfully updated.'
        format.html { 
          if(!params[:from_event].blank?)
            redirect_to(event_url(params[:from_event]))
          elsif(params[:from_org].present?)
            redirect_to(organization_url(params[:from_org]))
          else
            redirect_to( venue_path(@venue) )
          end
          }
        format.xml  { head :ok }
      else
        if params[:preview]
          @venue.attributes = params[:venue].to_h
          @venue.geocode if @venue.valid?
        end
        format.html { render :action => "edit" }
        format.xml  { render :xml => @venue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /venues/1
  # DELETE /venues/1.xml
  def destroy
    @venue = Venue.find(params[:id])

    if @venue.events.count > 0
      message = "Cannot destroy venue that has associated events, you must reassociate all its events first."
      respond_to do |format|
        format.html {
          flash[:failure] = message
          redirect_to( venue_path(@venue) )
        }
        format.xml {
          render :xml => message, :status => :unprocessable_entity
        }
      end
    else
      @venue.destroy
      respond_to do |format|
        format.html { redirect_to(venues_path, :flash => {:success => "\"#{@venue.title}\" has been deleted"}) }
        format.xml { head :ok }
      end
    end
  end

  # GET /venues/duplicates
  def duplicates
    @type = params[:type]
    begin
      @grouped_venues = Venue.find_duplicates_by_type(@type)
    rescue ArgumentError => e
      @grouped_venues = {}
      flash[:failure] = "#{e}"
    end

    @page_title = "Duplicate Venue Squasher"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grouped_venues }
    end
  end

protected

  def ical_export(venue)
    events = venue.events.order("start_time ASC").non_duplicates
    render(:body => Event.to_ical(events, :url_helper => lambda{|event| event_url(event)}), :mime_type => 'text/calendar')
  end

  class UntaintedParams < SimpleDelegator
    def for(action)
      respond_to?("for_#{action}") ? send("for_#{action}") : __getobj__
    end

    def for_create
      permit(*form_params, venue: venue_params)
    end

    def for_destroy
      permit(:authenticity_token, :id)
    end

    def for_duplicates
      permit(:type)
    end

    def for_edit
      permit(:id)
    end

    def for_index
      permit(:callback, :closed, :include_closed, :query, :tag, :term, :type, :val, :wifi)
    end

    def for_new
      permit(:layout)
    end

    def for_show
      permit(:id, :callback)
    end

    def for_update
      permit(*form_params, :id, :from_event, :from_org, venue: venue_params)
    end

    def form_params
      [:authenticity_token, :preview, :trap_field]
    end

    private def venue_params
      [ :access_notes, :description, :email, :force_geocoding, :latitude,
        :locality, :longitude, :postal_code, :region, :street_address,
        :telephone, :title, :url, :wifi,
      ]
    end
  end

end
