class SiteController < ApplicationController
  # Raise exception, mostly for confirming that exception_notification works
  def omfg
    raise ArgumentError, "OMFG"
  end

  # Render something to help benchmark stack without the views
  def hello
    render :text => "hello"
  end

  def index
    redirect_to(events_path(:format => params[:format]))
  end
  
  # Displays the about page.
  def about; end

  def opensearch
    respond_to do |format|
      format.xml { render :content_type => 'application/opensearchdescription+xml' }
    end
  end

  def search
    event = Event.find_event(params[:search])
    venue = Venue.find_venue(params[:search])
    if event != [] 
      redirect_to '/events/'+event.first.id.to_s
    elsif venue != []
      redirect_to '/venues/'+venue.first.id.to_s
    else
      redirect_to '/'
    end
  end

end
