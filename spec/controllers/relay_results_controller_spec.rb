require "rails_helper"

RSpec.describe RelayResultsController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  before { sign_in admin_user }

  let!(:cat)         { Category.find(4) }
  let!(:club)        { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:competition) { Competition.create!(competition_name: "Relay Race", date: Date.new(2026, 5, 1), distance_type: "Ștafetă clasică") }
  let!(:group)       { Group.create!(competition: competition, group_name: "M21S") }

  def make_leg(name:, time:)
    runner     = Runner.create!(club: club, runner_name: name, surname: "X", gender: "M", yob: 2000)
    membership = Membership.create!(runner: runner, club: club)
    Result.create!(
      group: group, membership: membership, category_id: cat.id,
      date: competition.date, time: time, place: 1, status: Result::CONFIRMED,
      skip_processing: true
    )
  end

  let!(:leg1) { make_leg(name: "Ion",   time: 1800) }
  let!(:leg2) { make_leg(name: "Mihai", time: 1700) }
  let!(:leg3) { make_leg(name: "Andrei", time: 1900) }

  let(:valid_attributes) do
    {
      place:       1,
      time:        5400,
      team:        "MDA-1",
      date:        competition.date,
      category_id: cat.id,
      group_id:    group.id,
      results_id:  [ leg1.id, leg2.id, leg3.id ]
    }
  end

  describe "POST #create" do
    it "creates a new RelayResult" do
      expect {
        post :create, params: { relay_result: valid_attributes }, format: :json
      }.to change(RelayResult, :count).by(1)
      expect(response).to have_http_status(:ok)
    end

    it "returns the relay hydrated with legs preserving results_id order" do
      post :create, params: { relay_result: valid_attributes }, format: :json
      json = JSON.parse(response.body)
      expect(json["legs"].map { |l| l["id"] }).to eq([ leg1.id, leg2.id, leg3.id ])
      expect(json["legs"].first["full_name"]).to eq("Ion X")
    end

    it "rejects a payload with the wrong leg count for the relay type" do
      bad = valid_attributes.merge(results_id: [ leg1.id, leg2.id ])
      post :create, params: { relay_result: bad }, format: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "forbids non-admin users" do
      sign_out admin_user
      sign_in FactoryBot.create(:user)
      post :create, params: { relay_result: valid_attributes }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #index" do
    let!(:relay) { RelayResult.create!(valid_attributes) }

    it "filters by competition" do
      get :index, params: { competition: competition.id }, format: :json
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["team"]).to eq("MDA-1")
    end

    it "filters by group_data" do
      get :index, params: { group_data: group.id }, format: :json
      expect(JSON.parse(response.body).length).to eq(1)
    end

    it "returns relay rows with leg payloads" do
      get :index, params: { group_data: group.id }, format: :json
      json = JSON.parse(response.body)
      expect(json.first["legs"].length).to eq(3)
    end

    it "surfaces group_rang and group_clasa on each relay row" do
      group.update!(rang: 480, clasa: "4")

      get :index, params: { group_data: group.id }, format: :json
      row = JSON.parse(response.body).first

      expect(row["group_rang"]).to eq(480)
      expect(row["group_clasa"]).to eq("4")
      expect(row["group_name"]).to eq("M21S")
    end
  end

  describe "PATCH #update" do
    let!(:relay) { RelayResult.create!(valid_attributes) }

    it "updates the team" do
      patch :update, params: { id: relay.id, relay_result: { team: "MDA-A" } }, format: :json
      expect(response).to have_http_status(:ok)
      expect(relay.reload.team).to eq("MDA-A")
    end
  end

  describe "DELETE #destroy" do
    let!(:relay) { RelayResult.create!(valid_attributes) }

    it "destroys the relay result" do
      expect {
        delete :destroy, params: { id: relay.id }, format: :json
      }.to change(RelayResult, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
