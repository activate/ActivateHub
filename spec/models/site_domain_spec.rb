require "rails_helper"

RSpec.describe SiteDomain, type: :model do
  subject(:site_domain) { build(:site_domain) }

  it { should be_valid }

  it { should validate_presence_of(:site) }
  it { should validate_presence_of(:domain) }
  it { should validate_presence_of(:redirect) }

  it { should validate_uniqueness_of(:domain).case_insensitive }

  describe "#domain=" do
    it "downcases the domain on assignment" do
      expect { site_domain.domain = "FooBar.TEST" }
        .to change { site_domain.domain }.to("foobar.test")
    end
  end

end
