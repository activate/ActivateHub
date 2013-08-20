# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :abstract_event do |f|
    f.site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }
    source
  end
end
