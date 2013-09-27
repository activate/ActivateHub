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
  end
end
