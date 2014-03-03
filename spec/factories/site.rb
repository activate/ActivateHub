# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :site do
    name 'My Site'
    domain 'my.site'
    timezone 'Asia/Tokyo'
    locale 'en-x-foo-bar'
  end
end
