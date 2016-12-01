require 'spec_helper'

RSpec.describe Site, type: :model do
  subject(:site) { create(:site) }

  it { should be_valid }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:domain) }
  it { should validate_presence_of(:timezone) }
  it { should validate_presence_of(:locale) }

  it { should validate_uniqueness_of(:domain) }

  describe "::with_site" do
    let(:alt_site) { create(:site, :locale => 'en-locale-loco') }

    it "should call #with_site on the site matching domain" do
      Site.with_site(alt_site.domain) do |site|
        site.domain.should eq alt_site.domain
      end
    end
  end

  describe "use!" do
    it "sets the default site associated with model objects" do
      ActiveRecord::Base.should_receive(:current_site=).with(site)
      site.use!
    end

    it "sets the timezone to that of the site" do
      Time.should_receive(:zone=).with(site.timezone)
      site.use!
    end

    it "sets the locale to that of the site" do
      I18n.should_receive(:locale=).with(site.locale)
      site.use!
    end

    it "returns the site object" do
      site.use!.should eq site
    end
  end

  describe "#with_site" do
    context "within the passed block" do
      it "passes in the site as a argument" do
        site.with_site {|s| s.should eq site }
      end

      it "has the site's timezone set" do
        site.with_site { Time.zone.should eq Time.find_zone(site.timezone) }
      end

      it "has the site's locale set" do
        site.with_site { I18n.locale.to_s.should eq site.locale }
      end

      it "has the site set as the current_site for database queries" do
        site.with_site { ActiveRecord::Base.current_site.should eq site }
      end
    end

    context "when block has finished executing" do
      it "returns the last value from the block" do
        site.with_site { :batman }.should eq :batman
      end

      it "restores the original timezone" do
        expect { site.with_site { nil } }.to_not change { Time.zone }
      end

      it "restores the original locale" do
        expect { site.with_site { nil } }.to_not change { I18n.locale }
      end

      it "restores the original site scope" do
        expect { site.with_site { nil } } \
          .to_not change { ActiveRecord::Base.current_site }
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
          .to_not change { ActiveRecord::Base.current_site }
      end
    end
  end

end
