require 'spec_helper'

describe SourcesController do
  let(:organization) { create(:organization) }

  def default_url_options
    super.merge!({ :organization_id => organization.id })
  end

  describe "POST :import" do
    let(:source) { build(:source, :organization => organization) }
    let(:source_attrs) { source.attributes.reject {|k,v| v.nil? } }

    context "with a non-unique URL" do
      before(:each) { create(:source, :url => source.url) }

      it "should not create a new source object" do
        expect {
          post :import, :source => source_attrs
        }.to_not change { Source.count }
      end

      it "should persist changs to the source object" do
        post :import, :source => { :url => source.url, :title => "undisclosed" }
        assigns(:source).reload.title.should eq "undisclosed"
      end

      it "should try to import assocated events" do
        Source.any_instance.should_receive(:create_events!)
        post :import, :source => source_attrs
      end
    end

    context "with a unique URL" do
      it "should save a new source object" do
        expect {
          post :import, :source => source_attrs
        }.to change { Source.count }.by(1)
      end

      it "should try to import assocated events" do
        Source.any_instance.should_receive(:create_events!)
        post :import, :source => source_attrs
      end
    end

    describe "is given problematic sources" do
      before do
        Source.should_receive(:find_or_create_from).and_return(source)
      end

      def assert_import_raises(exception)
        source.should_receive(:create_events!).and_raise(exception)
        post :import, :source => {:url => "http://invalid.host"}
      end

      it "should fail when host responds with an error" do
        assert_import_raises(OpenURI::HTTPError.new("omfg", "bbq"))
        flash[:failure].should match /Couldn't download events/
      end

      it "should fail when host is not responding" do
        assert_import_raises(Errno::EHOSTUNREACH.new("omfg"))
        flash[:failure].should match /Couldn't connect to remote site/
      end

      it "should fail when host is not found" do
        assert_import_raises(SocketError.new("omfg"))
        flash[:failure].should match /Couldn't find IP address for remote site/
      end

      it "should fail when host requires authentication" do
        assert_import_raises(SourceParser::HttpAuthenticationRequiredError.new("omfg"))
        flash[:failure].should match /requires authentication/
      end
    end

    it "should limit the number of created events to list in the flash" do
      max_display = SourcesController::MAXIMUM_EVENTS_TO_DISPLAY_IN_FLASH
      events = 1.upto(max_display + 5).map { build_stubbed(:event) }
      Source.any_instance.should_receive(:to_events).and_return(events)

      post :import, :source => { :url => source.url }
      flash[:success].should match /And 5 other events/si
    end
  end

  describe "GET :index" do
    it "should be successful" do
      get :index
      response.should be_success
    end

    it "should assign the sources to @sources" do
      source = create(:source, :organization => organization)
      get :index
      assigns(:sources).should eq [source]
    end

    context ":format => :html" do
      it "should render the :index template" do
        get :index, :format => :html
        expect(response).to render_template(:index)
      end
    end

    context ":format => :xml" do
      it "should render the found sources as xml" do
        get :index, :format => :xml
        response.content_type.should eq 'application/xml'
      end
    end
  end

  describe "GET :show" do
    context "source doesn't exist" do
      it "should redirect to the new source page" do
        get :show, :id => 'MI7'
        response.should redirect_to(new_organization_source_path)
      end

      it "should provide a failure message" do
        get :show, :id => 'MI7'
        expect(flash.keys).to include(:failure)
      end
    end

    context "source exists" do
      let(:source) { create(:source, :organization => organization) }

      it "should be successful" do
        get :show, :id => source.id
        response.should be_success
      end

      it "should assign the source to @source" do
        get :show, :id => source.id
        assigns(:source).should eq source
      end

      context ":format => :html" do
        it "should render the :show template" do
          get :show, :id => source.id, :format => :html
          expect(response).to render_template(:show)
        end
      end

      context ":format => :xml" do
        it "should render the source as xml" do
          get :show, :id => source.id, :format => :xml
          response.content_type.should eq 'application/xml'
        end
      end
    end
  end

  describe "GET :new" do
    it "should be successful" do
      get :new
      response.should be_success
    end

    it "should assign the newly initialized source to @source" do
      get :new
      assigns(:source).should be_present
    end

    it "@source should be a new record" do
      get :new
      expect(assigns(:source).new_record?).to be_true
    end

    context ":format => :html" do
      it "should render the :new template" do
        get :new, :format => :html
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET :edit" do
    context "source doesn't exist" do
      it "should raise an error" do
        expect { get :edit, :id => 'MI7' }.to raise_error
      end
    end

    context "source exists" do
      let(:source) { create(:source, :organization => organization) }

      it "should be successful" do
        get :edit, :id => source.id
        response.should be_success
      end

      it "should assign the source to @source" do
        get :edit, :id => source.id
        assigns(:source).should eq source
      end

      context ":format => :html" do
        it "should render the :edit template" do
          get :edit, :id => source.id, :format => :html
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe "POST :create" do
    context "with valid source attributes" do
      # attributes_for(:source) doesn't return what I expect w/ this version of FG
      let(:source_attrs) { build(:source, :organization => organization).attributes }

      it "should save the source object" do
        expect {
          post :create, :source => source_attrs
        }.to change { Source.count }.by(1)
      end

      it "should assign the source to @source" do
        post :create, :source => source_attrs
        assigns(:source).should_not be_nil
      end

      it "should redirect to the source show page" do
        post :create, :source => source_attrs

        path = organization_source_path(
          :organization_id => organization.id,
          :id => assigns(:source).id
        )

        expect(response).to redirect_to(path)
      end
    end

    context "with invalid source attributes" do
      it "should not save the source object" do
        expect { post :create, :source => {} }.to_not change { Source.count }
      end

      it "should render the :new template" do
        post :create, :source => {}
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PUT :update" do
    context "source doesn't exist" do
      it "should raise an error" do
        expect { put :update, :id => 'MI7' }.to raise_error
      end
    end

    context "source exists" do
      let(:source) { create(:source, :organization => organization) }

      it "should assign the source to @source" do
        put :update, :id => source.id, :source => source.attributes
        assigns(:source).should_not be_nil
      end

      context "source changes are valid" do
        it "should persist changs to the source object" do
          put :update, :id => source.id, :source => { :title => "undisclosed" }
          assigns(:source).reload.title.should eq "undisclosed"
        end

        it "should redirect to the source show page" do
          put :update, :id => source.id, :source => source.attributes

          path = organization_source_path(
            :organization_id => organization.id,
            :id => assigns(:source).id
          )

          expect(response).to redirect_to(path)
        end
      end

      context "source changes are invalid" do
        it "should not persist changes to the source object" do
          put :update, :id => source.id, :source => { :url => "" }
          assigns(:source).reload.url.should == source.url
        end

        it "should render the :edit template" do
          put :update, :id => source.id, :source => { :url => "" }
          expect(response).to render_template(:edit)
        end

        it "should provide an error message" do
          put :update, :id => source.id, :source => { :url => "" }
          expect(flash.keys).to include(:error)
        end
      end
    end
  end

  describe "DELETE :destroy" do
    context "source doesn't exist" do
      it "should raise an error" do
        expect { delete :destroy, :id => 'MI7' }.to raise_error
      end
    end

    context "source exists" do
      let(:source) { create(:source, :organization => organization) }

      it "should remove the object from the database" do
        source # initialize now, let(...) is lazy

        expect {
          delete :destroy, :id => source.id
        }.to change { Source.count }.by(-1)
      end

      it "should call destroy on source object (not delete)" do
        # we want to ensure any destroy hooks are triggered (paper trail, etc)
        Source.any_instance.should_receive(:destroy)
        delete :destroy, :id => source.id
      end

      it "should redirect to the index page" do
        delete :destroy, :id => source.id
        expect(response).to redirect_to(organization_sources_url)
      end
    end
  end

end
