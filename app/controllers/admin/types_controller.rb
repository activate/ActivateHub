class Admin::TypesController < AdminController
  respond_to :html, :json

  def index
    @types = Type.all
    respond_with [:admin, @types]
  end

  def show
    @type = Type.find(params[:id])

    @events = @type.events.order('created_at desc').limit(50)
    @sources = @type.sources

    respond_with [:admin, @type]
  end

  def new
    @type = Type.new
    respond_with [:admin, @type]
  end

  def create
    @type = Type.new

    params[:type][:name].downcase!
    @type.attributes = params[:type]

    if @type.save
      respond_with [:admin, @type]
    else
      respond_with @type
    end
  end

  def destroy
    @type = Type.find(params[:id])

    @type.destroy unless @type.any_items?
    respond_with :admin, @type
  end
end
