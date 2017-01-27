require "rails_helper"

RSpec.describe "Topic Admin Section", type: :request do
  describe "GET /admin/topics", :requires_admin do
    let(:index_path) { "/admin/topics" }

    let!(:enabled_topic) { create(:topic, enabled: true) }
    let!(:disabled_topic) { create(:topic, enabled: false) }

    def test_authenticated_request
      get index_path
    end

    it "returns a list of both enabled and disabled topics for the site" do
      get index_path
      expect(response).to have_http_status(200)
      expect(response.body).to include(enabled_topic.name)
      expect(response.body).to include(disabled_topic.name)
    end

    it "excludes topics for other sites" do
      offsite_topic = create(:topic, site: create(:site))
      get index_path
      expect(response).to have_http_status(200)
      expect(response.body).to_not include(offsite_topic.name)
    end
  end

  describe "GET /admin/topics/:topic_id", :requires_admin do
    let!(:topic) { create(:topic) }
    let(:show_path) { "/admin/topics/#{topic.id}" }

    def test_authenticated_request
      get show_path
    end

    it "returns information about the topic" do
      get show_path
      expect(response).to have_http_status(200)
      expect(response.body).to include(topic.name)
    end

    context "with associated content" do
      let!(:event) { create(:event, topics: [topic]) }
      let!(:organization) { create(:organization, topics: [topic]) }
      let!(:source) { create(:source, organization: organization, topics: [topic]) }

      it "includes associated content in response" do
        get show_path
        expect(response).to have_http_status(200)
        expect(response.body).to include(event.title)
        expect(response.body).to include(organization.name)
        expect(response.body).to include(source.name)
      end
    end
  end

  describe "GET /admin/topics/new", :requires_admin do
    let(:new_path) { "/admin/topics/new" }

    def test_authenticated_request
      get new_path
    end

    it "renders a form" do
      get new_path
      expect(response).to have_http_status(200)
      expect(response.body).to include("<form")
      expect(response.body).to include(admin_topics_path) # submission url
    end
  end

  describe "POST /admin/topics", :requires_admin do
    let(:create_path) { "/admin/topics" }
    let(:topic_params) { { name: "mYTopiC" } }
    let(:params) { { topic: topic_params } }

    def test_authenticated_request
      post create_path, params: params
    end

    it "creates a new topic and redirect to show page" do
      expect { post create_path, params: params }
        .to change { Topic.count }.by(1)

      topic = Topic.order(:id).last
      expect(response).to redirect_to(admin_topic_path(topic.id))
    end

    context "when a name is not provided" do
      let(:topic_params) { super().merge(name: "") }

      it "it renders a form with errors" do
        expect { post create_path, params: params }
          .to_not change { Topic.count }

        expect(response).to have_http_status(422)
        expect(response.body).to include("<form")

        expected_error = Topic.new.errors.generate_message(:name, :blank)
        expect(response.body).to include(expected_error)
      end
    end
  end

  describe "GET /admin/topics/:topic_id", :requires_admin do
    let!(:topic) { create(:topic) }
    let(:edit_path) { "/admin/topics/#{topic.id}" }

    def test_authenticated_request
      get edit_path
    end

    it "renders a form" do
      get edit_path
      expect(response).to have_http_status(200)
      expect(response.body).to include("<form")
      expect(response.body).to include(topic.name) # form field value
      expect(response.body).to include(admin_topic_path(topic.id)) # submission url
    end
  end

  describe "PUT /admin/topics/:topic_id", :requires_admin do
    let!(:topic) { create(:topic) }
    let(:update_path) { "/admin/topics/#{topic.id}" }
    let(:topic_params) { { name: "mYTopiC" } }
    let(:params) { { topic: topic_params } }

    def test_authenticated_request
      put update_path, params: params
    end

    it "updates the topic and returns to the show page" do
      expect { put update_path, params: params }
        .to change { topic.reload.name }.to(topic_params[:name])

      expect(response).to redirect_to(admin_topic_path(topic.id))
    end

    context "when a name is not provided" do
      let(:topic_params) { super().merge(name: "") }

      it "it renders a form with errors" do
        expect { put update_path, params: params }
          .to_not change { topic.reload.name }

        expect(response).to have_http_status(422)
        expect(response.body).to include("<form")

        expected_error = Topic.new.errors.generate_message(:name, :blank)
        expect(response.body).to include(expected_error)
      end
    end
  end

  describe "DELETE /admin/topics/:topic_id", :requires_admin do
    let!(:topic) { create(:topic) }
    let(:destroy_path) { "/admin/topics/#{topic.id}" }

    def test_authenticated_request
      delete destroy_path
    end

    it "destroys the topic and returns to index page" do
      expect { delete destroy_path }.to change { Topic.count }.by(-1)
      expect(response).to redirect_to(admin_topics_path)
    end

    context "when events are associated with the topic"do
      let!(:event) { create(:event, topics: [topic]) }

      it "does not allow the topic to be destroyed" do
        expect { delete destroy_path }.to_not change { Topic.count }
        expect(response).to have_http_status(409) # Conflict
      end
    end
  end

end
