require "rails_helper"

RSpec.describe ParserController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  describe "authorization" do
    context "when signed out" do
      it "redirects GET #index to root" do
        get :index
        expect(response).to redirect_to(root_path)
      end

      it "redirects GET #iof_runners to root" do
        get :iof_runners
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as non-admin" do
      let(:non_admin) { FactoryBot.create(:user) }
      before { sign_in non_admin }

      it "redirects GET #index to root" do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as admin" do
      before { sign_in admin_user }

      it "permits GET #index" do
        get :index
        expect(response).to be_successful
      end
    end
  end
end
