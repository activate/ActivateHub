class TopicsController < ApplicationController
  # GET /topics/1
  # GET /topics/1.xml
  def show
    begin
      @topic = Topic.find_by_name(params[:name], :include => [:events])
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to('/')
    end

    @page_title = 'Topic: ' + @topic.name

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @topic }
    end
  end


end
