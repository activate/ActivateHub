# Timecop is not currently wiping or truncating nsec/usec values correctly,
# which causes time comparisons to fail even though they look the same, see:
#   https://github.com/travisjeffery/timecop/issues/56
#   https://github.com/travisjeffery/timecop/issues/60
#   https://github.com/travisjeffery/timecop/issues/97

class Time
  def nsec; 0; end
  def usec; 0; end
end

class ActiveSupport::TimeWithZone
  def ==(other)
    if other.is_a?(Time)
      self.to_i == other.to_i
    else
      false
    end
  end
end
