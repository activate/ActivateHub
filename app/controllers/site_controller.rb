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
    event = Event.find_by_title(params[:search])
    venue = Venue.find_by_title(params[:search])
    if event != nil
      redirect_to '/events/'+event.id.to_s
    elsif venue != nil
      redirect_to '/venues/'+venue.id.to_s
    else
      redirect_to '/'
    end
  end
end
