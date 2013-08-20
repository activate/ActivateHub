# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :topic do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    sequence(:name) {|n| "topic #{n}" }
  end
end
