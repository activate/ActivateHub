require 'rails_helper'

RSpec.describe Site, type: :model do
  subject(:site) { create(:site) }

  it { should be_valid }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:domain) }
  it { should validate_presence_of(:timezone) }
  it { should validate_presence_of(:locale) }

  it { should validate_uniqueness_of(:domain).case_insensitive }

  # Ensure any cases of #use! in examples are cleaned up
  around {|ex| site.with_site { ex.run } }

  describe "(callbacks)" do
    it "creates a new non-redirect site domain record when site is created" do
      site = build(:site)
      expect { site.save! }.to change { SiteDomain.count }.by(1)

      domain = site.site_domains.find_by_domain(site.domain)
      expect(domain).to be_present
      expect(domain.redirect?).to_not be true
    end
  end

  describe "::with_site" do
    let(:alt_site) { create(:site, :locale => 'en-locale-loco') }

    it "should call #with_site on the site matching domain" do
      Site.with_site(alt_site.domain) do |site|
        expect(site.domain).to eq alt_site.domain
      end
    end
  end

  describe "#domain=" do
    it "downcases the domain on assignment" do
      expect { site.domain = "FooBar.TEST" }
        .to change { site.domain }.to("foobar.test")
    end
  end

  describe "#use!" do
    it "sets the default site associated with model objects" do
      expect(ApplicationRecord).to receive(:current_site=).with(site)
      site.use!
    end

    it "sets the timezone to that of the site" do
      expect(Time).to receive(:zone=).with(site.timezone)
      site.use!
    end

    it "sets the locale to that of the site" do
      expect(I18n).to receive(:locale=).with(site.locale)
      site.use!
    end

    it "returns the site object" do
      expect(site.use!).to eq site
    end
  end

  describe "::without_site" do
    context "within the passed block" do
      it "sets the timezone to UTC" do
        Site.without_site do
          expect(Time.zone).to eq Time.find_zone('UTC')
          expect(Time.zone).to_not eq Time.find_zone(site.timezone) # Ensure changed
        end
      end

      it "sets the locale to default locale" do
        Site.without_site do
          expect(I18n.locale).to eq I18n.default_locale
          expect(I18n.locale.to_s).to_not eq site.locale
        end
      end

      it "clear the current_site to use for database queries" do
        expect(ApplicationRecord.current_site).to_not be_nil
        Site.without_site { expect(ApplicationRecord.current_site).to be_nil }
      end
    end

    context "when the block has finished executing" do
      it "returns the last value from the block" do
        expect(Site.without_site { :batman }).to eq :batman
      end

      it "restores the original timezone" do
        expect { Site.without_site { nil } }.to_not change { Time.zone }
      end

      it "restores the original locale" do
        expect { Site.without_site { nil } }.to_not change { I18n.locale }
      end

      it "restores the original site scope" do
        expect { Site.without_site { nil } } \
          .to_not change { ApplicationRecord.current_site }
      end
    end
  end

  describe "#with_site" do
    context "within the passed block" do
      it "passes in the site as a argument" do
        site.with_site {|s| expect(s).to eq site }
      end

      it "has the site's timezone set" do
        site.with_site { expect(Time.zone).to eq Time.find_zone(site.timezone) }
      end

      it "has the site's locale set" do
        site.with_site { expect(I18n.locale.to_s).to eq site.locale }
      end

      it "has the site set as the current_site for database queries" do
        site.with_site { expect(ApplicationRecord.current_site).to eq site }
      end
    end

    context "when block has finished executing" do
      it "returns the last value from the block" do
        expect(site.with_site { :batman }).to eq :batman
      end

      it "restores the original timezone" do
        expect { site.with_site { nil } }.to_not change { Time.zone }
      end

      it "restores the original locale" do
        expect { site.with_site { nil } }.to_not change { I18n.locale }
      end

      it "restores the original site scope" do
        expect { site.with_site { nil } } \
          .to_not change { ApplicationRecord.current_site }
      end
    end

    context "when an error is raised in the block" do
      it "propagates the error" do
        expect { site.with_site { raise 'POW!' } }.to raise_error('POW!')
      end

      it "restores the original timezone" do
        expect { site.with_site { raise 'WHAM!' } rescue nil } \
          .to_not change { Time.zone }
      end

      it "restores the original locale" do
        expect { site.with_site { raise 'SOCK!' } rescue nil } \
          .to_not change { I18n.locale }
      end

      it "restores the original site scope" do
        expect { site.with_site { raise 'ZONK!' } rescue nil } \
          .to_not change { ApplicationRecord.current_site }
      end
    end

    context "when multiple threads are set to different sites" do
      let(:other_site) { create(:site) }

      it "treats each thread's site selection independently" do
        expect { Thread.new { site.use! }.join }
          .to_not change { ApplicationRecord.current_site }
      end
    end
  end

end
