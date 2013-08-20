# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    name 'My Org'
  end
end
