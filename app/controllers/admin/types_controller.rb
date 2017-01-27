class Admin::TypesController < AdminController
  respond_to :html, :json

  def index
    @types = Type.all
    respond_with :admin, @types
  end

  def show
    @type = Type.find(params[:id])

    preload_associations(@type)
    respond_with :admin, @type
  end

  def new
    @type = Type.new
    respond_with :admin, @type
  end

  def create
    @type = Type.new

    params[:type][:name].downcase!
    @type.attributes = params.require(:type).permit(:name)

    if @type.save
      flash[:success] = t('.success')
      respond_with :admin, @type
    else
      respond_with @type, status: 422
    end
  end

  def edit
    @type = Typee.find(params[:id])
    respond_with :admin, @type
  end

  def update
    @type = Type.find(params[:id])

    if @type.update_attributes(params.require(:type).permit(:name, :enabled))
      flash[:success] = t('.success')
      respond_with :admin, @type
    else
      respond_with :admin, @type, status: 422
    end
  end

  def destroy
    @type = Type.find(params[:id])

    if !@type.any_items? && @type.destroy
      flash[:success] = t('.success')
      respond_with :admin, :types
    else
      flash[:failure] = t('.associated_content')
      preload_associations(@type)
      render 'show', status: 409
    end
  end

  private def preload_associations(type)
    @events = type.events.order('created_at desc').limit(50)
    @sources = type.sources
  end

end
