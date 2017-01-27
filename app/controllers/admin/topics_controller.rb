class Admin::TopicsController < AdminController
  respond_to :html, :json

  def index
    @topics = Topic.all
    respond_with :admin, @topics
  end

  def show
    @topic = Topic.find(params[:id])

    preload_associations(@topic)
    respond_with :admin, @topic
  end

  def new
    @topic = Topic.new
    respond_with :admin, @topic
  end

  def create
    @topic = Topic.new

    params[:topic][:name].downcase!
    @topic.attributes = params.require(:topic).permit(:name)

    if @topic.save
      flash[:success] = t('.success')
      respond_with :admin, @topic
    else
      respond_with @topic, status: 422
    end
  end

  def edit
    @topic = Topic.find(params[:id])
    respond_with :admin, @topic
  end

  def update
    @topic = Topic.find(params[:id])

    if @topic.update_attributes(params.require(:topic).permit(:name, :enabled))
      flash[:success] = t('.success')
      respond_with :admin, @topic
    else
      respond_with :admin, @topic, status: 422
    end
  end

  def destroy
    @topic = Topic.find(params[:id])

    if !@topic.any_items? && @topic.destroy
      flash[:success] = t('.success')
      respond_with :admin, :topics
    else
      flash[:failure] = t('.associated_content')
      preload_associations(@topic)
      render 'show', status: 409
    end
  end

  private def preload_associations(topic)
    @events = topic.events.order('created_at desc').limit(50)
    @organizations = topic.organizations
    @sources = topic.sources
  end

end
