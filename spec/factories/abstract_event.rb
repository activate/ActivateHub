# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :abstract_event do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }
    source

    trait :future do
      start_time { Time.zone.now + 7.days }
    end
  end
end
