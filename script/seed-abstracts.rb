#!/usr/bin/env ruby
#
# Seed AbstractLocation and AbstractEvent objects with earliest known
# versions of venues and events imported from 3rd party calendars. The
# new recurring event import backend performs de-duplication and event
# updates at the source level; this allows us to match against original
# values found during the last import instead of current values stored
# with events.  Doing this allows us to change venue and event titles
# without triggering a new event on next import, as well as identify
# which fields have been edited manually using the web interface so we
# don't accidentally blow those changes away with data from the upstream
# calendar.
#
# You should run this script if you plan to take advantage of recurring
# event imports from 3rd party calendars.
#

Venue.where("source_id IS NOT NULL").order(:id).each do |venue|
  # tries to build the original venue as first imported
  if version = venue.versions.where("object is not null").first
    venue = version.reify rescue venue # okay w/ current venue if fails
  end

  # double-check that the venue is still associated with a source
  next if !venue.source # ...and not just an _id to oblivion

  abstract_location = AbstractLocation.new(
    :site_id        => venue.site_id,
    :source_id      => venue.source_id,
    :venue_id       => venue.id,
    :url            => venue.url,
    :title          => venue.title,
    :description    => venue.description,
    :address        => venue.address,
    :street_address => venue.street_address,
    :locality       => venue.locality,
    :region         => venue.region,
    :postal_code    => venue.postal_code,
    :country        => venue.country,
    :latitude       => venue.latitude,
    :longitude      => venue.longitude,
    :email          => venue.email,
    :telephone      => venue.telephone,
    :created_at     => venue.created_at,
    :updated_at     => venue.created_at,
    :result         => 'created',
  )

  # double-check that another abstract venue isn't identical; some
  # imports, mostly web-based, created the exact same venue multiple
  # times due to bugs and otherwise renaming the venue's title
  next if abstract_location.find_existing

  abstract_location.save!
end

Event.where("source_id IS NOT NULL").order(:id).each do |event|
  # tries to build original event as first imported
  if version = event.versions.where("object is not null").first
    event = version.reify rescue event # okay w/ current event if fails
  end

  # double-check that the event is still associated with a source
  next if !event.source # ...and not just an _id to oblivion

  abstract_event = AbstractEvent.new(
    :site_id     => event.site_id,
    :source_id   => event.source_id,
    :event_id    => event.id,
    :url         => event.url,
    :title       => event.title,
    :start_time  => event.start_time,
    :end_time    => event.end_time,
    :description => event.description,
    :created_at  => event.created_at,
    :updated_at  => event.created_at,
    :result      => 'created',
  )

  location = AbstractLocation.where(:venue_id => event.venue_id).first
  abstract_event.abstract_location = location

  # our Event-based dupe detection wasn't very good, so some events got
  # reimported multiple times due to changed event titles and times
  next if abstract_event.find_existing

  abstract_event.save!
end
