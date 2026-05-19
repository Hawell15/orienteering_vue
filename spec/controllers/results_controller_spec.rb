require "rails_helper"

RSpec.describe ResultsController, type: :controller do
  let!(:category) { Category.create!(category_name: "Pro", points: 100, validaty_period: 2) }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category" } }
  let!(:club) { Club.create!(club_name: "Test Club") }
  let!(:runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000) }
  let!(:competition) { Competition.create!(competition_name: "Test Comp", date: Date.new(2025, 6, 1), distance_type: "Sprint") }
  let!(:group) { Group.create!(competition: competition, group_name: "M21") }
  let!(:membership) { Membership.create!(runner: runner, club: club) }
  let!(:result) { Result.create!(group: group, membership: membership, category: category, date: Date.new(2025, 6, 1), place: 1, time: 3600, status: "confirmed") }
  let(:valid_attributes) { { place: 2, time: 4000, date: "2025-06-01", status: "unconfirmed", category_id: category.id, group_id: group.id, runner_id: runner.id, club_id: club.id } }

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

    it "includes computed fields" do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json.first).to have_key("full_name")
      expect(json.first).to have_key("club_name")
      expect(json.first).to have_key("competition_name")
      expect(json.first).to have_key("group_name")
    end

    context "with scopes" do
      it "filters by status" do
        Result.create!(group: group, membership: membership, category: category, date: Date.today, status: "pending")
        get :index, params: { status: [ "confirmed" ] }, format: :json
        json = JSON.parse(response.body)
        expect(json.all? { |r| r["status"] == "confirmed" }).to be true
      end

      it "filters by category" do
        get :index, params: { category: category.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "filters by group_data" do
        other_group = Group.create!(competition: competition, group_name: "W21")
        Result.create!(group: other_group, membership: membership, category: category, date: Date.today)
        get :index, params: { group_data: group.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "filters by date range" do
        Result.create!(group: group, membership: membership, category: category, date: Date.new(2020, 1, 1))
        get :index, params: { date: { from: "2025-01-01", to: "2025-12-31" } }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "sorts by date" do
        get :index, params: { sorting: { sort_by: "date", direction: "desc" } }, format: :json
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    it "returns a successful HTML response" do
      get :show, params: { id: result.id }
      expect(response).to be_successful
    end

    it "returns JSON with nested associations" do
      get :show, params: { id: result.id }, format: :json
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(result.id)
      expect(json["category"]).to be_present
      expect(json["membership"]).to be_present
      expect(json["membership"]["runner"]).to be_present
      expect(json["membership"]["club"]).to be_present
      expect(json["group"]).to be_present
      expect(json["group"]["competition"]).to be_present
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
      it "creates a new Result" do
        expect {
          post :create, params: { result: valid_attributes }, format: :json
        }.to change(Result, :count).by(1)
      end

      it "returns ok status" do
        post :create, params: { result: valid_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "creates or finds the membership" do
        post :create, params: { result: valid_attributes }, format: :json
        new_result = Result.last
        expect(new_result.membership.runner_id).to eq(runner.id)
        expect(new_result.membership.club_id).to eq(club.id)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Result).to receive(:save).and_return(false)
        post :create, params: { result: valid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the result" do
        patch :update, params: { id: result.id, result: valid_attributes.merge(place: 3) }, format: :json
        result.reload
        expect(result.place).to eq(3)
      end

      it "returns ok status" do
        patch :update, params: { id: result.id, result: valid_attributes.merge(place: 3) }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Result).to receive(:update).and_return(false)
        patch :update, params: { id: result.id, result: valid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the result" do
      expect {
        delete :destroy, params: { id: result.id }
      }.to change(Result, :count).by(-1)
    end

    it "redirects to results list (HTML)" do
      delete :destroy, params: { id: result.id }
      expect(response).to redirect_to(results_path)
    end

    it "returns no_content (JSON)" do
      delete :destroy, params: { id: result.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET #filters" do
    it "returns clubs, runners, competitions, and categories" do
      get :filters, format: :json
      json = JSON.parse(response.body)
      expect(json).to have_key("clubs")
      expect(json).to have_key("runners")
      expect(json).to have_key("competitions")
      expect(json).to have_key("categories")
    end
  end
end
