my_formats = {
  :yyyymmdd => '%Y-%m-%d',
  :long_date => '%A, %B %d, %Y',
}

Time::DATE_FORMATS.merge!(my_formats)
Date::DATE_FORMATS.merge!(my_formats)

# Keep milliseconds from being included in JSON responses
ActiveSupport::JSON::Encoding.time_precision = 0
