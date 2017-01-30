# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :site_domain do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }
    sequence(:domain) {|n| "my.site.domain#{n}" }
  end
end
