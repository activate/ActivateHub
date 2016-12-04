class SiteController < ApplicationController

  def params
    @params ||= UntaintedParams.new(super).for(action_name)
  end

  # Raise exception, mostly for confirming that exception_notification works
  def omfg
    raise ArgumentError, "OMFG"
  end

  # Render something to help benchmark stack without the views
  def hello
    render :plain => "hello"
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

  class UntaintedParams < SimpleDelegator
    def for(action)
      respond_to?("for_#{action}") ? send("for_#{action}") : __getobj__
    end

    def for_index
      permit(:format)
    end
  end

end
