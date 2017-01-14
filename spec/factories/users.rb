# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "foo-#{n}@example.com" }
    password "asdfasdf"
    password_confirmation "asdfasdf"

    factory :admin, traits: [:admin]
  end

  trait :admin do
    admin true
  end

end
