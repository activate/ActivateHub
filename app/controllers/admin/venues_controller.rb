class Admin::VenuesController < AdminController
  respond_to :html, :json

  include SquashManyDuplicatesMixin # provides squash_many_duplicates

  def params
    @params ||= super.permit! # FIXME: Add support for strong params
  end

  def index
    @venues = Venue.non_duplicates

    # ransack-compatible param-based search (might use real gem later if enough uses)
    if params[:type] == 'missing_lat_long'
      @venues = @venues.where('latitude is null or longitude is null')
    end

    @venues = @venues.order(:title)

    respond_with [:admin, @venues]
  end

  def duplicates
    @venues = Venue.non_duplicates.order(:title)
    @groupings = []

    if params[:type] == 'matching_title'
      @groupings = @venues.group_by(&:title)

    elsif params[:type] == 'matching_lat_long'
      @venues = @venues.where('latitude is not null and longitude is not null')
      @groupings = @venues.group_by {|v| [v.latitude.to_s, v.longitude.to_s] }
    end

    @groupings = @groupings.reject {|k,v| v.size < 2 }

    respond_with @groupings
  end

end
