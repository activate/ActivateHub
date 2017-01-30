require "rails_helper"

RSpec.describe "Site Tenancy", type: :request do
  let(:other_site) { create(:site) }

  it "returns a 404 not found if site domain is not found" do
    expect { get events_url(host: site.domain + "x") }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it "treats site domains as case-insensitive" do
    get events_url(host: site.domain.upcase)
    expect(response).to be_success

    get events_url(host: site.domain.downcase)
    expect(response).to be_success
  end

  it "restrict content to that associated with site" do
    event = create(:event, title: "EVENT71443", site: site)
    other_event = create(:event, title: "EVENT47614", site: other_site)

    get events_url
    expect(response.body).to include(event.title)
    expect(response.body).to_not include(other_event.title)
  end

  describe "Alternate Domains" do
    subject(:alt_domain) { create(:site_domain, site: site) }
    before { host! alt_domain.domain }

    it "treats site domains as case-insensitive" do
      get events_url(host: alt_domain.domain.upcase)
      expect(response).to be_redirect

      get events_url(host: alt_domain.domain.downcase)
      expect(response).to be_redirect
    end

    context "when alternate domain is set to redirect" do
      before { alt_domain.update_attributes!(redirect: true) }

      it "redirect requests to primary domain associated with site" do
        get events_url(host: alt_domain.domain)
        expect(response).to redirect_to(events_url(host: site.domain))
      end

      it "retains path part of url in the redirect" do
        event = create(:event)
        get event_url(event, host: alt_domain.domain)
        expect(response).to redirect_to(event_url(event, host: site.domain))

        org = create(:organization)
        get organization_url(org, host: alt_domain.domain)
        expect(response).to redirect_to(organization_url(org, host: site.domain))
      end
    end

    context "when alternate domain is not set to redirect" do
      before { alt_domain.update_attributes!(redirect: false) }

      it "does not redirect request to primary domain" do
        get events_url(host: alt_domain.domain)
        expect(response).to have_http_status(:ok)
      end

      it "generates links using the alternate domain" do
        get events_url(host: alt_domain.domain, format: :atom)
        expect(response.body).to include(alt_domain.domain)
        expect(response.body).to_not include(site.domain)
      end

      it "tenantizes site similar to primary domain" do
        event = create(:event, title: "EVENT71443", site: site)
        other_event = create(:event, title: "EVENT47614", site: other_site)

        get events_url(host: alt_domain.domain)
        expect(response.body).to include(event.title)
        expect(response.body).to_not include(other_event.title)
      end
    end
  end

end
