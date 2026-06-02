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
      before { allow_any_instance_of(Grover).to receive(:to_pdf).and_return("%PDF-stub") }

      it "renders a PDF via Grover (default style)" do
        get :show, params: { id: competition.id }, format: :pdf

        expect(response).to be_successful
        expect(response.content_type).to start_with("application/pdf")
        expect(response.body).to eq("%PDF-stub")
      end

      it "renders the modern style template + layout when style=modern" do
        expect(controller).to receive(:render_to_string).with(hash_including(template: "competitions/pdf_modern", layout: "pdf_modern")).and_call_original
        get :show, params: { id: competition.id, style: "modern" }, format: :pdf
        expect(response).to be_successful
      end

      it "renders the minimal style template + layout when style=minimal" do
        expect(controller).to receive(:render_to_string).with(hash_including(template: "competitions/pdf_minimal", layout: "pdf_minimal")).and_call_original
        get :show, params: { id: competition.id, style: "minimal" }, format: :pdf
        expect(response).to be_successful
      end

      it "falls back to default for an unknown style param" do
        expect(controller).to receive(:render_to_string).with(hash_including(template: "competitions/pdf", layout: "pdf")).and_call_original
        get :show, params: { id: competition.id, style: "haxor" }, format: :pdf
        expect(response).to be_successful
      end

      it "renders the confirmations template with the modern layout" do
        expect(controller).to receive(:render_to_string).with(hash_including(template: "competitions/pdf_confirmations", layout: "pdf_modern")).and_call_original
        get :show, params: { id: competition.id, style: "confirmations" }, format: :pdf
        expect(response).to be_successful
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

  describe "confirmations PDF bucketing" do
    let!(:no_cat)   { Category.find(Category::NO_CATEGORY_ID) }
    let!(:cat3)     { Category.find(3) }
    let!(:cat4)     { Category.find(4) }
    let!(:club)     { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
    let!(:group)    { Group.create!(competition: competition, group_name: "M21", clasa: "4") }
    let!(:reduction_group)     { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)         { |g| g.competition = competition; g.group_name = "REDUCTION" } }
    let!(:title_group)         { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }
    let!(:three_results_group) { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)              { |g| g.competition = competition; g.group_name = "THREE" } }

    def make_runner(name:, best_category: cat4)
      Runner.create!(club: club, runner_name: name, surname: "X", gender: "M", yob: 2000, category: best_category, best_category: best_category, category_valid: Date.new(2099, 1, 1))
    end

    def make_prior_result(runner, category:)
      prior_comp  = Competition.create!(competition_name: "Prior", date: competition.date - 6.months, distance_type: "Sprint")
      prior_group = Group.create!(competition: prior_comp, group_name: "P")
      Result.create!(group: prior_group,
                     membership: Membership.find_or_create_by!(runner: runner, club: club),
                     category: category, date: prior_comp.date, time: 1000, place: 1,
                     status: Result::CONFIRMED, skip_processing: true)
    end

    def make_result(runner, category:, status:)
      Result.create!(group: group,
                     membership: Membership.find_or_create_by!(runner: runner, club: club),
                     category: category, date: competition.date, time: 1500, place: 1,
                     status: status, skip_processing: true)
    end

    before do
      allow_any_instance_of(Grover).to receive(:to_pdf).and_return("%PDF-stub")
    end

    it "buckets results into capped / improved / extended" do
      capped_runner   = make_runner(name: "Capped")
      improved_runner = make_runner(name: "Improved")
      extended_runner = make_runner(name: "Extended")

      make_prior_result(extended_runner, category: cat4)
      make_prior_result(improved_runner, category: cat4)

      make_result(capped_runner,   category: cat4, status: Result::CAPPED)
      make_result(improved_runner, category: cat3, status: Result::CONFIRMED)
      make_result(extended_runner, category: cat4, status: Result::CONFIRMED)

      get :show, params: { id: competition.id, style: "confirmations" }, format: :pdf

      data = controller.instance_variable_get(:@pdf_confirmations).buckets
      expect(data[:capped].map(&:id)).to contain_exactly(Result.find_by(membership: Membership.find_by(runner: capped_runner)).id)
      expect(data[:improved].map(&:id)).to contain_exactly(Result.find_by(membership: Membership.find_by(runner: improved_runner), group: group).id)
      expect(data[:extended].map(&:id)).to contain_exactly(Result.find_by(membership: Membership.find_by(runner: extended_runner), group: group).id)
    end

    it "excludes unconfirmed / NO_CATEGORY / pending child results" do
      runner = make_runner(name: "Skip")
      make_result(runner, category: cat4, status: Result::UNCONFIRMED)
      make_result(make_runner(name: "Empty"), category: no_cat, status: Result::CONFIRMED)

      get :show, params: { id: competition.id, style: "confirmations" }, format: :pdf

      data = controller.instance_variable_get(:@pdf_confirmations).buckets
      expect(data[:capped]).to be_empty
      expect(data[:improved]).to be_empty
      expect(data[:extended]).to be_empty
    end
  end

  describe "GET #confirmations" do
    let!(:c_cat3)   { Category.find(3) }
    let!(:c_cat4)   { Category.find(4) }
    let!(:c_club)   { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
    let!(:c_group)  { Group.create!(competition: competition, group_name: "M21", clasa: "4") }
    let!(:c_reduction) { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)         { |g| g.competition = competition; g.group_name = "REDUCTION" } }
    let!(:c_title)     { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }
    let!(:c_three)     { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)              { |g| g.competition = competition; g.group_name = "THREE" } }

    it "renders the HTML mount point" do
      get :confirmations, params: { id: competition.id }
      expect(response).to be_successful
    end

    it "returns JSON with competition + three buckets" do
      runner = Runner.create!(club: c_club, runner_name: "Ion", surname: "Pop", gender: "M", yob: 2000,
                              category: c_cat4, best_category: c_cat4, category_valid: Date.new(2099, 1, 1))
      Result.create!(group: c_group,
                     membership: Membership.create!(runner: runner, club: c_club),
                     category: c_cat4, date: competition.date, time: 1500, place: 1,
                     status: Result::CONFIRMED, skip_processing: true)

      get :confirmations, params: { id: competition.id }, format: :json
      json = JSON.parse(response.body)

      expect(json.keys.sort).to eq(%w[capped competition extended improved])
      expect(json["competition"]["id"]).to eq(competition.id)
      expect(json["improved"].size + json["extended"].size).to eq(1)
      row = (json["improved"] + json["extended"]).first
      expect(row["full_name"]).to eq("Ion Pop")
      expect(row["runner_id"]).to eq(runner.id)
      expect(row["group_name"]).to eq("M21")
    end

    it "is accessible to non-admin / signed-out users" do
      sign_out admin_user
      get :confirmations, params: { id: competition.id }, format: :json
      expect(response).to be_successful
    end
  end

  describe "POST #telegram_results" do
    it "delegates to TelegramCompetitionNotifier with request.base_url and returns the message count" do
      expect(TelegramCompetitionNotifier).to receive(:notify).with(competition, host: instance_of(String)).and_return(3)
      post :telegram_results, params: { id: competition.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("sent" => 3)
    end

    it "returns sent=0 when no reportable results exist" do
      expect(TelegramCompetitionNotifier).to receive(:notify).and_return(0)
      post :telegram_results, params: { id: competition.id }, format: :json
      expect(JSON.parse(response.body)).to eq("sent" => 0)
    end

    it "returns 503 with a structured error when the token is missing" do
      expect(TelegramCompetitionNotifier).to receive(:notify).and_raise(TelegramNotifier::TokenMissingError, "Telegram bot token not configured")
      post :telegram_results, params: { id: competition.id }, format: :json
      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)).to eq("sent" => 0, "error" => "Telegram bot token not configured")
    end

    it "is forbidden for non-admin users" do
      sign_out admin_user
      sign_in FactoryBot.create(:user)
      post :telegram_results, params: { id: competition.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST #reimport_wre_points" do
    context "when competition has no wre_id" do
      it "returns unprocessable_content" do
        post :reimport_wre_points, params: { id: competition.id }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when competition has a wre_id" do
      let!(:wre_competition) do
        Competition.create!(
          competition_name: "WRE Race",
          date:             Date.new(2025, 6, 1),
          distance_type:    "Lungă",
          wre_id:           9999
        )
      end

      it "delegates to WreRaceReimporter and returns the updated count" do
        reimporter = instance_double(WreRaceReimporter, call: 7)
        expect(WreRaceReimporter).to receive(:new).with(wre_competition).and_return(reimporter)

        post :reimport_wre_points, params: { id: wre_competition.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("updated" => 7)
      end

      it "is forbidden for non-admin users" do
        sign_out admin_user
        sign_in FactoryBot.create(:user)
        post :reimport_wre_points, params: { id: wre_competition.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
