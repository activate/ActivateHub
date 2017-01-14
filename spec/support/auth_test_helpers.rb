RSpec.shared_examples "requires user login" do
  let(:user) { create(:user) }

  before(:each, :requires_user => true) do
    sign_in user
  end

  it "redirects to user login when not logged in" do
    sign_out user
    test_authenticated_request
    expect(response).to redirect_to(user_session_path)
  end

  it "allows performing action when logged in" do
    sign_in user
    test_authenticated_request
    expect(response).to_not redirect_to(user_session_path)
  end
end

RSpec.shared_examples "requires admin login" do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  before(:each, :requires_admin => true) do
    sign_in admin
  end

  it "redirects to user login when not logged in" do
    sign_out admin
    test_authenticated_request
    expect(response).to redirect_to(user_session_path)
  end

  it "redirects to root site url when not an admin" do
    sign_out admin
    sign_in user
    test_authenticated_request
    expect(response).to redirect_to(root_path)
  end

  it "allows performing action when logged in admin user" do
    sign_in admin
    test_authenticated_request
    expect(response).to_not redirect_to(user_session_path)
    expect(response).to_not redirect_to(root_path)
  end
end
