# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :abstract_location do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    sequence(:title) {|n| "Underground Strawberry-Turnip Cross-Breeding Facility ##{n}" }

    source

    trait :invalid do
      title nil
    end

  end
end
