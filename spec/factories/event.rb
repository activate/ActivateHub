# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    # TODO: reduce to minimum required to pass validation (drop sequences unless uniq)
    sequence(:title) { |n| "Event #{n}" }
    sequence(:description) { |n| "Description of Event #{n}." }
    start_time { Time.zone.now + 1.hour }
    end_time { self.start_time + 1.hours }

    trait :future do
      start_time { Time.zone.now + 7.days }
    end
  end

  factory :event_with_venue, :parent => :event do
    venue
  end

  factory :duplicate_event, :parent => :event do
    association :duplicate_of, :factory => :event
  end
end
