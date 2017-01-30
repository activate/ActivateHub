require "rails_helper"
require_relative "site_scoping_examples"

RSpec.describe Version do

  it_behaves_like "site-scoped model",
    factory: ->(site) { FactoryGirl.create(:event, site: site).versions.first }

end
