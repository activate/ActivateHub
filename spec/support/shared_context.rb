RSpec.shared_context "site" do
  let(:site) { Site.find_by_domain(ENV["TEST_REQ_HOST"]) }

  # Make sure the host used in requests matches our site
  before(:each, type: :request) do
    host! site.domain
  end

end
