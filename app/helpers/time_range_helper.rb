require 'time_range'

module TimeRangeHelper
  def normalize_time(start_time, end_time=nil, opts=nil)
    TimeRange.new(start_time, end_time, opts).to_s.html_safe
    # datetime_format(time,time.min == 0 ? '%I%p' : '%I:%M%p').downcase
  end  
end
