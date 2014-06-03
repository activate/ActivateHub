class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.order(:name)

    if @topic = params[:topic].presence
      @organizations = @organizations.joins(:topics).where('topics.name = ?', @topic)
    end

    @topics = Topic.joins(:organizations).select("DISTINCT topics.name AS name").reorder(:name)
  end

  # GET /organizations/1
  # GET /organizations/1.xml
  def show
    begin
      @organization = Organization.find(params[:id], :include => [:events])

      if @organization.sources.none?
        flash[:notice] = "This organization has no events. " +
          view_context.link_to(t('organizations.item.sources.add'), new_organization_source_path(@organization))
      end
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to(new_organization_path)
    end

    @future_events = @organization.events.future.non_duplicates.reorder('start_time asc').limit(10)
    @past_events = @organization.events.past.non_duplicates.reorder('start_time desc').limit(10)

    @page_title = @organization.name

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # GET /organizations/new
  # GET /organizations/new.xml
  def new
    @organization = Organization.new(params[:organization])
    @page_title = "Add an Organization"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # GET /organizations/1/edit
  def edit
    @organization = Organization.find(params[:id])
  end


  # POST /organizations
  # POST /organizations.xml
  def create
    params[:organization][:topic_ids] = create_missing_refs(params[:organization][:topic_ids], Topic)

    @organization = Organization.new(params[:organization].merge(venue_id: params["event"]["venue_id"]))
    @organization.associate_with_venue(venue_ref(params[:event], params[:venue_name]))
    has_new_venue = @organization.venue && @organization.venue.new_record?

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't create this organization because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && params[:preview].nil? && @organization.save
        flash[:success] = 'Organization was successfully created.'
        if has_new_venue && params[:venue_name].present?
          flash[:success] += " Please tell us more about where it's being held."
          format.html {redirect_to(edit_venue_url(@organization.venue, :from_org => @organization.id))}
        else
          format.html { redirect_to( organization_path(@organization) ) }
          format.xml  { render :xml => @organization, :status => :created, :location => @organization }
        end
      else
        @organization.valid? if params[:preview]
        format.html { render :action => "new" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /organizations/1
  # PUT /organizations/1.xml
  def update
    params[:organization][:topic_ids] = create_missing_refs(params[:organization][:topic_ids], Topic)

    @organization = Organization.find(params[:id])

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't update this organization because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && params[:preview].nil? && @organization.update_attributes(params[:organization].merge(venue_id: params["event"]["venue_id"]))
        flash[:success] = 'Organization was successfully updated.'
        format.html { redirect_to( organization_path(@organization) ) }
        format.xml  { head :ok }
      else
        if params[:preview]
          @organization.attributes = params[:organization]
          @organization.valid?
        end
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

    # DELETE /organizations/1
  # DELETE /organizations/1.xml
  def destroy
    @organization = Organization.find(params[:id])
    Organization.destroy(params[:id])

    respond_to do |format|
      format.html { redirect_to(organizations_url, :flash => {:success => "\"#{@organization.title}\" has been deleted"}) }
      format.xml  { head :ok }
    end
  end

end
