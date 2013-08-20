# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :source do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    url 'http://a.valid.url.test'
    title 'My Source'
  end
end
