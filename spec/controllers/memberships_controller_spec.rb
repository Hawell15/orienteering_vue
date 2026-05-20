require "rails_helper"

RSpec.describe MembershipsController, type: :controller do
  let!(:category) { Category.create!(category_name: "Test") }
  let!(:club) { Club.create!(club_name: "Test Club") }
  let!(:runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000) }
  let!(:membership) { Membership.create!(runner: runner, club: club) }
  let!(:club2) { Club.create!(club_name: "Other Club") }
  let(:valid_attributes) { { runner_id: runner.id, club_id: club2.id } }

  describe "GET #index" do
    it "returns a successful HTML response" do
      get :index
      expect(response).to be_successful
    end

    it "returns a successful JSON response" do
      get :index, format: :json
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end

    it "includes full_name, club_name, and results_count" do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json.first).to have_key("full_name")
      expect(json.first).to have_key("club_name")
      expect(json.first).to have_key("results_count")
    end

    context "with scopes" do
      it "filters by club" do
        other_runner = Runner.create!(club: club2, category: category, best_category: category, runner_name: "Jane", surname: "Smith", gender: "W", yob: 2001)
        Membership.create!(runner: other_runner, club: club2)
        get :index, params: { club: club.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "filters by runner" do
        other_runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "Jane", surname: "Smith", gender: "W", yob: 2001)
        Membership.create!(runner: other_runner, club: club)
        get :index, params: { runner: runner.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "sorts by id" do
        get :index, params: { sorting: { sort_by: "id", direction: "asc" } }, format: :json
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    it "returns JSON with runner and club" do
      get :show, params: { id: membership.id }, format: :json
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(membership.id)
      expect(json["runner"]).to be_present
      expect(json["club"]).to be_present
      expect(json["runner"]["runner_name"]).to eq("John")
      expect(json["club"]["club_name"]).to eq("Test Club")
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Membership" do
        expect {
          post :create, params: { membership: valid_attributes }, format: :json
        }.to change(Membership, :count).by(1)
      end

      it "returns ok status" do
        post :create, params: { membership: valid_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Membership).to receive(:save).and_return(false)
        post :create, params: { membership: valid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the membership" do
        patch :update, params: { id: membership.id, membership: { club_id: club2.id } }, format: :json
        membership.reload
        expect(membership.club_id).to eq(club2.id)
      end

      it "returns ok status" do
        patch :update, params: { id: membership.id, membership: { club_id: club2.id } }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Membership).to receive(:update).and_return(false)
        patch :update, params: { id: membership.id, membership: { club_id: nil } }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the membership" do
      expect {
        delete :destroy, params: { id: membership.id }
      }.to change(Membership, :count).by(-1)
    end

    it "redirects to memberships list (HTML)" do
      delete :destroy, params: { id: membership.id }
      expect(response).to redirect_to(memberships_path)
    end

    it "returns no_content (JSON)" do
      delete :destroy, params: { id: membership.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET #filters" do
    it "returns clubs and runners" do
      get :filters, format: :json
      json = JSON.parse(response.body)
      expect(json).to have_key("clubs")
      expect(json).to have_key("runners")
    end
  end
end
