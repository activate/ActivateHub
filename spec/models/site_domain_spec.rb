require "rails_helper"

RSpec.describe SiteDomain, type: :model do
  subject(:site_domain) { build(:site_domain) }

  it { should be_valid }

  it { should validate_presence_of(:site) }
  it { should validate_presence_of(:domain) }
  it { should validate_presence_of(:redirect) }

  it { should validate_uniqueness_of(:domain) }

end
