# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :abstract_location do
    site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }

    sequence(:title) {|n| "Underground Strawberry-Turnip Cross-Breeding Facility ##{n}" }

    source

    trait :invalid do
      title ' '
    end

    trait :w_address do
      address 'Unlabelled'
      street_address 'Not enough houses'
      locality "You're getting colder"
      region 'Likely Hell'
      postal_code '99762'
      country 'US'
    end

    trait :w_venue_attributes do
      w_address

      sequence(:url) {|n| "http://my.venue-#{n}.url.test/" }
      description { "For that glow-in-your-mouth goodness!" }
      latitude { (64.503889).to_d }
      longitude { (-165.399444).to_d }
      email { "iceman@extreme-tourguides.test" }
      telephone { "000-000-0000" }
      tags { %w(food farming gmo underground radium) }
    end
  end
end
