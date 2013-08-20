class SourceParser # :nodoc:
  class Meetup < Base
    label :Meetup
    url_pattern %r{^http://(?:www\.)?meetup\.com/[^/]+/events/([^/]+)/?}

    def self.to_abstract_events(opts={})
      if SECRETS.meetup_api_key.present?
        self.to_abstract_events_api_helper(
          :url => opts[:url],
          :error => 'problem',
          :api => lambda { |event_id|
            [
              "https://api.meetup.com/2/event/#{event_id}",
              {
                :query => {
                  :key => SECRETS.meetup_api_key,
                  :sign => 'true'
                }
              }
            ]
          }
        ) do |data, event_id|
          event = AbstractEvent.new(
            :title       => data['name'],
            :description => data['description'],
            # Meetup sends us milliseconds since the epoch in UTC
            :start_time  => Time.at(data['time']/1000).utc,
            :url         => data['event_url'],
            :abstract_location => to_abstract_location(data['venue']),
            :tags        => ["meetup:event=#{event_id}", "meetup:group=#{data['group']['urlname']}"],
          )

          [event]
        end
      else
        self.to_abstract_events_wrapper(
          opts,
          SourceParser::Ical,
          %r{^http://(?:www\.)?meetup\.com/([^/]+)/events/([^/]+)/?},
          lambda { |matcher| "http://www.meetup.com/#{matcher[1]}/events/#{matcher[2]}/ical/omgkittens.ics" }
        )
      end
    end

    def self.to_abstract_location(value, opts={})
      if value.present?
        location = AbstractLocation.new(
          :title   => value['name'],
          :street_address => [value['address_1'], value['address_2'], value['address_3']].compact.join(", "),
          :locality => value['city'],
          :region => value['state'],
          :postal_code => value['zip'],
          :country => value['country'],
          :telephone => value['phone'],
          :tags => ["meetup:venue=#{value['id']}"],
        )
      else
        location = nil
      end

      return location
    end
  end
end
