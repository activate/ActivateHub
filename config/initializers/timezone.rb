# When an ambiguous time is encountered, treat time as non daylight-savings.
#
# This works around some code in RiCal that converts UTC dates to local time
# in order to find the UTC offset of a date. This is normally not a problem
# as events don't start or end durinng an ambiguous window (i.e. 1-2am when
# a daylight savings transition takes place). Background workers that create
# events can run during this time window, and the created_at or updated_at
# timestamps are also have this calculation applied.
TZInfo::Timezone.default_dst = false

# A more accurate solution would be to check if the offset results in a time
# that matches the original UTC time or using an activesupport way of
# calculating the time offset; implementing this solution, however, would
# require monkey-patching private/un-documented code in the ri_cal gem.
#
# The code in the ri_cal gem that causes an issue is in
# lib/ri_cal/component/calendar.rb:142-144:
#
#     def rational_utc_offset(local)
#       RiCal.RationalOffset[tzinfo.period_for_local(local, true).utc_total_offset]
#     end
#
