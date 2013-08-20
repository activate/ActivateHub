Factory.define :site do |f|
  f.name 'My Site'
  f.domain 'my.site'
end

Factory.define :organization do |f|
  f.site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }
  f.name 'My Org'
end

Factory.define :source do |f|
  f.site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }
  f.title 'My Source'
  f.url 'http://a.valid.url'
  #f.association :organization
end

Factory.define :venue do |f|
  f.site { Site.find_by_domain(ENV['TEST_REQ_HOST']) }
  f.sequence(:title) { |n| "Venue #{n}" }
  f.sequence(:description) { |n| "Description of Venue #{n}." }
  f.sequence(:address) { |n| "Address #{n}" }
  f.sequence(:street_address) { |n| "Street #{n}" }
  f.sequence(:locality) { |n| "City #{n}" }
  f.sequence(:region) { |n| "Region #{n}" }
  f.sequence(:postal_code) { |n| "#{n}-#{n}-#{n}" }
  f.sequence(:country) { |n| "Country #{n}" }
  f.sequence(:latitude) { |n| "45.#{n}".to_f }
  f.sequence(:longitude) { |n| "122.#{n}".to_f }
  f.sequence(:email) { |n| "info@venue#{n}.com" }
  f.sequence(:telephone) { |n| "(#{n}#{n}#{n}) #{n}#{n}#{n}-#{n}#{n}#{n}#{n}" }
  f.sequence(:url) { |n| "http://#{n}.com" }
  f.closed false
  f.wifi true
  f.access_notes "Access permitted."
end
