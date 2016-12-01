require 'spec_helper'

RSpec.describe Organization, type: :model do
  subject(:organization) { build(:organization) }

  # Tests for Organization:
  # - Creating an organization with 'viagra' as name should fail.
  # - Creating an organization without a name is not possible.
  # - If the email is included, it should be valid

  it { should be_valid }

  describe "in general" do
    before(:each) do
      @org = Organization.new(:name => "My Organization", :contact_name => "Juana", :email => "juana@myorganization.org")
    end
    specify {expect(@org).to be_valid}
  end

  describe "when creating nameless organizations" do
    before(:each) do
      @org = Organization.new()
    end
    specify {expect(@org).to_not be_valid}
  end

  describe "when creating spam" do
    before(:each) do
      @org = Organization.new(:name => "Some like viagra")
    end

    specify {expect(@org).to_not be_valid}
  end

  describe "when adding email" do
    before(:each) do
      @org = Organization.new(:name => "Awsome Organization", :email => "juana is not awsome")
    end
    specify {expect(@org).to_not be_valid}
  end

  it "has a venue" do
    venue = create(:venue)
    org = create(:organization, venue_id: venue.id)

    expect(org.venue).to eq venue

    org.venue_id = nil
    org.save

    expect(org.venue).to be_nil
  end

  it "can be associated with a venue" do
    org = create(:organization)
    venue = create(:venue)

    expect(org.associate_with_venue(venue)).to eq venue
  end

end
