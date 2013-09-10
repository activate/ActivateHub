class Admin::VenuesController < AdminController
  respond_to :html, :json

  def index
    @venues = Venue.non_duplicates

    # ransack-compatible param-based search (might use real gem later if enough uses)
    if params[:latitude_null].presence && params[:longitude_null].presence
      @venues = @venues.where(:latitude => nil, :longitude => nil)
    end

    @venues = @venues.order(:title)

    respond_with [:admin, @venues]
  end

end
