require "rails_helper"

RSpec.describe CompetitionsController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  before { sign_in admin_user }

  let!(:competition) { Competition.create!(competition_name: "Cupa Moldovei", date: Date.new(2025, 6, 1), distance_type: "Sprint", location: "Chisinau", country: "Moldova") }
  let(:valid_attributes) { { competition_name: "New Race", date: Date.new(2025, 7, 1), distance_type: "Medie", location: "Balti", country: "Moldova" } }
  let(:invalid_attributes) { { competition_name: nil } }

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
      expect(json.map { |c| c["competition_name"] }).to include("Cupa Moldovei")
    end

    context "with scopes" do
      it "filters by search" do
        get :index, params: { search: "cupa" }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "filters by country" do
        Competition.create!(competition_name: "Foreign Race", date: Date.today, distance_type: "Sprint", country: "Romania")
        get :index, params: { country: "Moldova" }, format: :json
        json = JSON.parse(response.body)
        expect(json.all? { |c| c["country"] == "Moldova" }).to be true
      end

      it "filters by distance_type" do
        Competition.create!(competition_name: "Long", date: Date.today, distance_type: "Lungă")
        get :index, params: { distance_type: "Sprint" }, format: :json
        json = JSON.parse(response.body)
        expect(json.all? { |c| c["distance_type"] == "Sprint" }).to be true
      end

      it "sorts by competition_name" do
        Competition.create!(competition_name: "Alpha Race", date: Date.today, distance_type: "Sprint")
        get :index, params: { sorting: { sort_by: "competition_name", direction: "asc" } }, format: :json
        json = JSON.parse(response.body)
        expect(json.first["competition_name"]).to eq("Alpha Race")
      end

      it "filters by date range" do
        Competition.create!(competition_name: "Old Race", date: Date.new(2020, 1, 1), distance_type: "Sprint")
        get :index, params: { date: { from: "2025-01-01", to: "2025-12-31" } }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["competition_name"]).to eq("Cupa Moldovei")
      end

      it "respects limit param" do
        3.times { |i| Competition.create!(competition_name: "Race #{i}", date: Date.today, distance_type: "Sprint") }
        get :index, params: { limit: 2 }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
      end
    end
  end

  describe "GET #show" do
    it "returns a successful HTML response" do
      get :show, params: { id: competition.id }
      expect(response).to be_successful
    end

    it "returns JSON with correct attributes" do
      get :show, params: { id: competition.id }, format: :json
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(competition.id)
      expect(json["competition_name"]).to eq("Cupa Moldovei")
      expect(json["distance_type"]).to eq("Sprint")
    end

    context "with pdf format" do
      it "renders a PDF via Grover" do
        allow_any_instance_of(Grover).to receive(:to_pdf).and_return("%PDF-stub")

        get :show, params: { id: competition.id }, format: :pdf

        expect(response).to be_successful
        expect(response.content_type).to start_with("application/pdf")
        expect(response.body).to eq("%PDF-stub")
      end
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
      it "creates a new Competition" do
        expect {
          post :create, params: { competition: valid_attributes }, format: :json
        }.to change(Competition, :count).by(1)
      end

      it "returns ok status" do
        post :create, params: { competition: valid_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns the created competition as JSON" do
        post :create, params: { competition: valid_attributes }, format: :json
        json = JSON.parse(response.body)
        expect(json["competition_name"]).to eq("New Race")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Competition).to receive(:save).and_return(false)
        post :create, params: { competition: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the competition" do
        patch :update, params: { id: competition.id, competition: { competition_name: "Updated Race" } }, format: :json
        competition.reload
        expect(competition.competition_name).to eq("Updated Race")
      end

      it "returns ok status" do
        patch :update, params: { id: competition.id, competition: { competition_name: "Updated" } }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Competition).to receive(:update).and_return(false)
        patch :update, params: { id: competition.id, competition: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "authorization on write actions" do
    let(:non_admin) { FactoryBot.create(:user) }

    context "when signed out" do
      before { sign_out admin_user }

      it "redirects HTML POST #create to root" do
        post :create, params: { competition: valid_attributes }
        expect(response).to redirect_to(root_path)
      end

      it "returns 403 for JSON POST #create" do
        post :create, params: { competition: valid_attributes }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when signed in as non-admin" do
      before { sign_in non_admin }

      it "returns 403 for JSON DELETE #destroy" do
        delete :destroy, params: { id: competition.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the competition" do
      expect {
        delete :destroy, params: { id: competition.id }
      }.to change(Competition, :count).by(-1)
    end

    it "redirects to competitions list (HTML)" do
      delete :destroy, params: { id: competition.id }
      expect(response).to redirect_to(competitions_path)
    end

    it "returns no_content (JSON)" do
      delete :destroy, params: { id: competition.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET #filters" do
    it "returns countries and distance_types" do
      get :filters, format: :json
      json = JSON.parse(response.body)
      expect(json).to have_key("countries")
      expect(json).to have_key("distance_types")
      expect(json["countries"]).to include("Moldova")
    end
  end

  describe "GET #ecn_ranking" do
    it "renders successfully" do
      get :ecn_ranking
      expect(response).to be_successful
    end

    it "returns JSON with default gender + date" do
      get :ecn_ranking, format: :json
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to be_an(Array)
    end

    it "accepts gender and date params" do
      get :ecn_ranking, params: { gender: "W", date: "2025-06-01" }, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #ecn_runner_results" do
    let!(:category) { Category.create!(category_name: "MSRM", full_name: "Maestru Sport", points: 100, validaty_period: 2) }
    let!(:club) { Club.create!(club_name: "Test Club") }
    let!(:runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "Ion", surname: "Pop", gender: "M", yob: 1990) }

    it "returns JSON with results and threshold for a runner" do
      get :ecn_runner_results, params: { runner_id: runner.id, date: "2025-06-01" }, format: :json
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json).to have_key("min_limit_points")
      expect(json).to have_key("limit_number")
      expect(json["results"]).to be_an(Array)
    end

    it "404s for an unknown runner" do
      expect {
        get :ecn_runner_results, params: { runner_id: 0, date: "2025-06-01" }, format: :json
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #distance_types" do
    it "returns the list of distance types" do
      get :distance_types, format: :json
      json = JSON.parse(response.body)
      expect(json).to include("Sprint", "Medie", "Lungă")
    end
  end

  describe "GET #group_filters" do
    it "returns groups and ecn/wre flags" do
      Group.create!(competition: competition, group_name: "M21")
      get :group_filters, params: { id: competition.id }, format: :json
      json = JSON.parse(response.body)
      expect(json).to have_key("groups")
      expect(json).to have_key("ecn")
      expect(json).to have_key("wre")
    end
  end
end
