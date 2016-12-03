class Admin::TopicsController < AdminController
  respond_to :html, :json

  def params
    @params ||= super.permit! # FIXME: Add support for strong params
  end

  def index
    @topics = Topic.all
    respond_with [:admin, @topics]
  end

  def show
    @topic = Topic.find(params[:id])

    @events = @topic.events.order('created_at desc').limit(50)
    @organizations = @topic.organizations
    @sources = @topic.sources

    respond_with [:admin, @topic]
  end

  def new
    @topic = Topic.new
    respond_with [:admin, @topic]
  end

  def create
    @topic = Topic.new

    params[:topic][:name].downcase!
    @topic.attributes = params[:topic].to_h

    if @topic.save
      respond_with [:admin, @topic]
    else
      respond_with @topic
    end
  end

  def destroy
    @topic = Topic.find(params[:id])

    @topic.destroy unless @topic.any_items?
    respond_with :admin, @topic
  end
end
