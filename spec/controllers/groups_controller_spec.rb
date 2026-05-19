require "rails_helper"

RSpec.describe GroupsController, type: :controller do
  let!(:competition) { Competition.create!(competition_name: "Test Comp", date: Date.new(2025, 6, 1), distance_type: "Sprint") }
  let!(:group) { Group.create!(competition: competition, group_name: "M21", rang: 1, clasa: "3") }
  let(:valid_attributes) { { group_name: "W18", competition_id: competition.id, rang: 2 } }
  let(:invalid_attributes) { { group_name: nil } }

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

    it "includes competition_name and results_count" do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json.first).to have_key("competition_name")
      expect(json.first).to have_key("results_count")
    end

    context "with scopes" do
      it "filters by search" do
        get :index, params: { search: "m21" }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to be >= 1
        expect(json.map { |g| g["group_name"] }).to include("M21")
      end

      it "filters by competition" do
        other_comp = Competition.create!(competition_name: "Other", date: Date.today, distance_type: "Sprint")
        Group.create!(competition: other_comp, group_name: "W21")
        get :index, params: { competition: competition.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "sorts by group_name" do
        Group.create!(competition: competition, group_name: "A10")
        get :index, params: { sorting: { sort_by: "group_name", direction: "asc" } }, format: :json
        json = JSON.parse(response.body)
        expect(json.first["group_name"]).to eq("A10")
      end

      it "filters by date range" do
        old_comp = Competition.create!(competition_name: "Old", date: Date.new(2020, 1, 1), distance_type: "Sprint")
        Group.create!(competition: old_comp, group_name: "W10")
        get :index, params: { date: { from: "2025-01-01", to: "2025-12-31" } }, format: :json
        json = JSON.parse(response.body)
        expect(json.all? { |g| g["group_name"] != "W10" }).to be true
      end
    end
  end

  describe "GET #show" do
    it "returns a successful JSON response with competition" do
      get :show, params: { id: group.id }, format: :json
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(group.id)
      expect(json["group_name"]).to eq("M21")
      expect(json["competition"]).to be_present
      expect(json["competition"]["competition_name"]).to eq("Test Comp")
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
      it "creates a new Group" do
        expect {
          post :create, params: { group: valid_attributes }, format: :json
        }.to change(Group, :count).by(1)
      end

      it "returns ok status" do
        post :create, params: { group: valid_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "normalizes group_name" do
        post :create, params: { group: valid_attributes.merge(group_name: "w 18") }, format: :json
        json = JSON.parse(response.body)
        expect(json["group_name"]).to eq("W18")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Group).to receive(:save).and_return(false)
        post :create, params: { group: valid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the group" do
        patch :update, params: { id: group.id, group: { rang: 5 } }, format: :json
        group.reload
        expect(group.rang).to eq(5)
      end

      it "returns ok status" do
        patch :update, params: { id: group.id, group: { rang: 5 } }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Group).to receive(:update).and_return(false)
        patch :update, params: { id: group.id, group: { rang: nil } }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the group" do
      expect {
        delete :destroy, params: { id: group.id }
      }.to change(Group, :count).by(-1)
    end

    it "redirects to groups list (HTML)" do
      delete :destroy, params: { id: group.id }
      expect(response).to redirect_to(groups_path)
    end

    it "returns no_content (JSON)" do
      delete :destroy, params: { id: group.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET #filters" do
    it "returns competitions and clase" do
      get :filters, format: :json
      json = JSON.parse(response.body)
      expect(json).to have_key("competitions")
      expect(json).to have_key("clase")
    end
  end
end
