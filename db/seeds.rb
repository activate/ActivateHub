# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Daley', :city => cities.first)
require 'date'

if Rails.env.development?
   User.create!({ email: "dev@example.org", password: "activate" })
end

site = Site.create!({ name: "activate_dev", domain: "localhost" })

venue = Venue.create!({
   title: "Danny's House",
   description: "Danny's Totally Rad Pad",
   postal_code: "97277",
   country: "USA",
   email: "carting@example.org",
   telephone: "(555)501-1234",
   site_id: site.id })

Organization.create!({
   name: "Danny's Awesome Go-Cart Extravaganza",
   url: "http://www.example.org/gocart",
   contact_name: "Danny Boy",
   email: "danny@example.org",
   site_id: site.id })

Event.create!({
   title: "Danny's Birthday",
   description: "Come celebrate Danny's 40th birthday!",
   start_time: DateTime.now,
   venue_id: venue.id,
   site_id: site.id
})

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