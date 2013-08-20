# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :type do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    sequence(:name) {|n| "type #{n}" }
  end
end
