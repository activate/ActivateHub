class TypesController < ApplicationController
  # GET /types/1
  # GET /types/1.xml
  def show
    begin
      @type = Type.find_by_name(params[:name], :include => [:events])
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to('/')
    end

    @page_title = 'Type: ' + @type.name

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @type }
    end
  end


end
