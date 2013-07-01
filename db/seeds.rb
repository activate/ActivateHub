# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Daley', :city => cities.first)
require 'date'
require 'faker'

if Rails.env.development?
   User.create!({ email: "dev@example.org", password: "activate" })
end

site = Site.create!({ name: "activate_dev", domain: "localhost" })

# Creates 20 random venue, organizations, and event database entries
counter = 20

while counter > 0
   venue = Venue.create!({
      title: Faker::Company::name,
      description: Faker::Lorem::paragraph(sentence_count=2),
      postal_code: Faker::Address::zip_code,
      country: Faker::Address::country,
      email: Faker::Internet::safe_email,
      telephone: Faker::PhoneNumber::phone_number,
      site_id: site.id
   })

   Organization.create!({
      name: Faker::Company::name,
      url: Faker::Internet::url,
      contact_name: Faker::Name::name,
      email: Faker::Internet::safe_email,
      site_id: site.id
   })

   Event.create!({
      title: Faker::Lorem::sentence(word_count=2),
      description: Faker::Lorem::paragraph(sentence_count=2),
      start_time: DateTime.now + rand(15),
      venue_id: venue.id,
      site_id: site.id
   })
   counter -= 1
   sleep 1 # Prevents hitting API call limit
end

Type.create!(
 [
   { name: 'volunteer', site_id: site.id },
   { name: 'social', site_id: site.id },
   { name: 'meeting', site_id: site.id },
   { name: 'educational', site_id: site.id },
   { name: 'rally', site_id: site.id },
   { name: 'other', site_id: site.id },
   { name: 'film screening', site_id: site.id }
 ])

 Topic.create!(
  [
   { name: 'animal rights', site_id: site.id },
   { name: 'arts', site_id: site.id  },
   { name: 'biking', site_id: site.id },
   { name: 'business', site_id: site.id },
   { name: 'community', site_id: site.id },
   { name: 'urban', site_id: site.id },
   { name: 'environment', site_id: site.id },
   { name: 'economics', site_id: site.id },
   { name: 'food', site_id: site.id },
   { name: 'health', site_id: site.id },
   { name: 'human rights', site_id: site.id },
   { name: 'politics', site_id: site.id },
   { name: 'transportation', site_id: site.id },
   { name: 'walking', site_id: site.id },
   { name: 'transit', site_id: site.id },
   { name: 'humanitarian aid', site_id: site.id },
   { name: 'war and peace', site_id: site.id }
  ])