# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :abstract_location do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    title 'Strawberry-Turnip Cross-Breeding Facility'

    source
  end
end
