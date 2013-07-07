# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
require 'date'
require 'faker'

if Rails.env.development?
  User.create!({ :email => "dev@example.org", :password => "activate" })

  # Creates 20 random venue, organizations, and event database entries
  site = Site.create!({ :name => "activate_dev", :domain => "localhost" })
  1.upto(20) do
    venue = Venue.create!({
      :title       => Faker::Company::name,
      :description => Faker::Lorem::paragraph(sentence_count=2),
      :postal_code => Faker::Address::zip_code,
      :country     => Faker::Address::country,
      :email       => Faker::Internet::safe_email,
      :telephone   => Faker::PhoneNumber::phone_number,
      :site_id     => site.id
    })

    Organization.create!({
      :name         => Faker::Company::name,
      :url          => Faker::Internet::url,
      :contact_name => Faker::Name::name,
      :email        => Faker::Internet::safe_email,
      :site_id      => site.id
    })

    Event.create!({
      :title       => Faker::Lorem::sentence(word_count=2),
      :description => Faker::Lorem::paragraph(sentence_count=2),
      :start_time  => DateTime.now + rand(15),
      :venue_id    => venue.id,
      :site_id     => site.id
    })

    sleep 1 # FIXME: find a work around to geocoding API limits
  end
end

types = [
  'volunteer', 'social', 'meeting', 'educational', 'rally',
  'film screening', 'other'
]

topics = [
  'animal rights', 'arts', 'biking', 'business', 'community', 'urban',
  'environment', 'economics', 'food', 'health', 'human rights', 'politics',
  'transportation', 'walking', 'transit', 'humanitarian aid',
  'war and peace'
]

Site.scoped.each do |site|
  types.each {|t| Type.create!(:name => t, :site_id => site.id) }
  topics.each {|t| Topic.create!(:name => t, :site_id => site.id) }
end
