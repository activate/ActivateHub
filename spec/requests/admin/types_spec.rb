require "rails_helper"

RSpec.describe "Type Admin Section", type: :request do
  describe "GET /admin/types", :requires_admin do
    let(:index_path) { "/admin/types" }

    let!(:enabled_type) { create(:type, enabled: true) }
    let!(:disabled_type) { create(:type, enabled: false) }

    def test_authenticated_request
      get index_path
    end

    it "returns a list of both enabled and disabled types for the site" do
      get index_path
      expect(response).to have_http_status(200)
      expect(response.body).to include(enabled_type.name)
      expect(response.body).to include(disabled_type.name)
    end

    it "excludes types for other sites" do
      offsite_type = create(:type, site: create(:site))
      get index_path
      expect(response).to have_http_status(200)
      expect(response.body).to_not include(offsite_type.name)
    end
  end

  describe "GET /admin/types/:type_id", :requires_admin do
    let!(:type) { create(:type) }
    let(:show_path) { "/admin/types/#{type.id}" }

    def test_authenticated_request
      get show_path
    end

    it "returns information about the type" do
      get show_path
      expect(response).to have_http_status(200)
      expect(response.body).to include(type.name)
    end

    context "with associated content" do
      let!(:event) { create(:event, types: [type]) }
      let!(:organization) { create(:organization) }
      let!(:source) { create(:source, organization: organization, types: [type]) }

      it "includes associated content in response" do
        get show_path
        expect(response).to have_http_status(200)
        expect(response.body).to include(event.title)
        expect(response.body).to include(source.name)
      end
    end
  end

  describe "GET /admin/types/new", :requires_admin do
    let(:new_path) { "/admin/types/new" }

    def test_authenticated_request
      get new_path
    end

    it "renders a form" do
      get new_path
      expect(response).to have_http_status(200)
      expect(response.body).to include("<form")
      expect(response.body).to include(admin_types_path) # submission url
    end
  end

  describe "POST /admin/types", :requires_admin do
    let(:create_path) { "/admin/types" }
    let(:type_params) { { name: "mYTopiC" } }
    let(:params) { { type: type_params } }

    def test_authenticated_request
      post create_path, params: params
    end

    it "creates a new type and redirect to show page" do
      expect { post create_path, params: params }
        .to change { Type.count }.by(1)

      type = Type.order(:id).last
      expect(response).to redirect_to(admin_type_path(type.id))
    end

    context "when a name is not provided" do
      let(:type_params) { super().merge(name: "") }

      it "it renders a form with errors" do
        expect { post create_path, params: params }
          .to_not change { Type.count }

        expect(response).to have_http_status(422)
        expect(response.body).to include("<form")

        expected_error = Type.new.errors.generate_message(:name, :blank)
        expect(response.body).to include(expected_error)
      end
    end
  end

  describe "GET /admin/types/:type_id", :requires_admin do
    let!(:type) { create(:type) }
    let(:edit_path) { "/admin/types/#{type.id}" }

    def test_authenticated_request
      get edit_path
    end

    it "renders a form" do
      get edit_path
      expect(response).to have_http_status(200)
      expect(response.body).to include("<form")
      expect(response.body).to include(type.name) # form field value
      expect(response.body).to include(admin_type_path(type.id)) # submission url
    end
  end

  describe "PUT /admin/types/:type_id", :requires_admin do
    let!(:type) { create(:type) }
    let(:update_path) { "/admin/types/#{type.id}" }
    let(:type_params) { { name: "mYTopiC" } }
    let(:params) { { type: type_params } }

    def test_authenticated_request
      put update_path, params: params
    end

    it "updates the type and returns to the show page" do
      expect { put update_path, params: params }
        .to change { type.reload.name }.to(type_params[:name])

      expect(response).to redirect_to(admin_type_path(type.id))
    end

    context "when a name is not provided" do
      let(:type_params) { super().merge(name: "") }

      it "it renders a form with errors" do
        expect { put update_path, params: params }
          .to_not change { type.reload.name }

        expect(response).to have_http_status(422)
        expect(response.body).to include("<form")

        expected_error = Type.new.errors.generate_message(:name, :blank)
        expect(response.body).to include(expected_error)
      end
    end
  end

  describe "DELETE /admin/types/:type_id", :requires_admin do
    let!(:type) { create(:type) }
    let(:destroy_path) { "/admin/types/#{type.id}" }

    def test_authenticated_request
      delete destroy_path
    end

    it "destroys the type and returns to index page" do
      expect { delete destroy_path }.to change { Type.count }.by(-1)
      expect(response).to redirect_to(admin_types_path)
    end

    context "when events are associated with the type"do
      let!(:event) { create(:event, types: [type]) }

      it "does not allow the type to be destroyed" do
        expect { delete destroy_path }.to_not change { Type.count }
        expect(response).to have_http_status(409) # Conflict
      end
    end
  end

end
