# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :source do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    url 'http://a.valid.url.test'
    title 'My Source'

    ignore do
      topics_count 0
      types_count 0
    end

    before(:create) do |source, evaluator|
      source.topics << create_list(:topic, evaluator.topics_count)
      source.types << create_list(:type, evaluator.types_count)
    end

    trait :w_organization do
      organization
    end

    trait :w_topics_types do
      topics_count 3
      types_count 2
    end
  end
end
