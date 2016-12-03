module AssociatedVenues
  def associate_with_venue(venue)
    venue = \
      case venue
      when Venue    then venue
      when NilClass then nil
      when String   then Venue.find_or_initialize_by(title: venue)
      when Fixnum   then Venue.find(venue)
      else raise TypeError, "Unknown type: #{venue.class}"
      end

    if venue && ((self.venue && self.venue != venue) || (!self.venue))
      self.venue = venue.progenitor
    elsif !venue && self.venue
      self.venue = nil
    end

    return self.venue
  end
end
