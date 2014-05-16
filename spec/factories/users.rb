# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    email "foo@example.com"
    password "asdfasdf"
    password_confirmation "asdfasdf"
  end
end
