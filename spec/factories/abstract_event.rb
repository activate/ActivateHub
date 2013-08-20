# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :abstract_event do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    title 'Mirror Games'
    start_time { Time.zone.now + 29.hours }
    end_time { Time.zone.now + 32.hours }

    source

    trait :future do
      start_time { Time.zone.now + 7.days }
    end
  end
end
