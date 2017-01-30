RSpec.shared_examples_for "site-scoped model" do |factory: described_class.downcase|

  before do
    [site, create(:site)].each do |site|
      factory.respond_to?(:call) \
        ? factory.call(site)          # Proc/Lambda
        : create(factory, site: site) # FactoryGirl
    end
  end

  context "when current site is not set" do
    around {|ex| Site.without_site { ex.run } }

    it "includes all sites in query" do
      site_ids = Version.all.pluck(:site_id).uniq
      expect(site_ids.size).to be > 1
    end
  end

  context "when current site is set" do
    around {|ex| site.with_site { ex.run } }

    it "limits queries to the current site" do
      site_ids = Version.all.pluck(:site_id).uniq
      expect(site_ids.size).to eq 1
      expect(site_ids.first).to eq site.id
    end
  end

end
