# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :abstract_event do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    sequence(:title) {|n| "'Theory of Insanity' Attempt ##{n}" }
    start_time { Time.zone.now + 29.hours }
    end_time { Time.zone.now + 32.hours }

    source

    trait :invalid do
      title nil
    end

    trait :future do
      start_time { Time.zone.now + 7.days }
    end

    trait :w_location do
      abstract_location
    end

    trait :w_event_attributes do
      sequence(:url) {|n| "http://my.event-#{n}.url.test/" }

      description do
        "After careful examination, we have concluded that our universe "  +
        "is really a multiverse that is being decompressed from a single " +
        "giant zip file.  Compression levels before the Big Bang suggest " +
        "we are not as random as we would like ourselves to believe."
      end

      tags { %w(universe everything nothing the-sysadmin-drives-a-jalopy) }
    end
  end
end
