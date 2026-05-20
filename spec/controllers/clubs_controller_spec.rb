require "rails_helper"

RSpec.describe ClubsController, type: :controller do
  let!(:club) { Club.create!(club_name: "Alpha Club", territory: "North", representative: "John", email: "alpha@test.com", phone: "123") }
  let(:valid_attributes) { { club_name: "Beta Club", territory: "South" } }
  let(:invalid_attributes) { { club_name: nil } }

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

    it "includes runners_count in JSON response" do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json.first).to have_key("runners_count")
    end

    context "with scopes" do
      it "filters by search" do
        get :index, params: { search: "alpha" }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["club_name"]).to eq("Alpha Club")
      end

      it "sorts by club_name desc" do
        Club.create!(club_name: "Zeta Club")
        get :index, params: { sorting: { sort_by: "club_name", direction: "desc" } }, format: :json
        json = JSON.parse(response.body)
        expect(json.first["club_name"]).to eq("Zeta Club")
      end
    end
  end

  describe "GET #show" do
    it "returns a successful HTML response" do
      get :show, params: { id: club.id }
      expect(response).to be_successful
    end

    it "returns JSON with correct attributes" do
      get :show, params: { id: club.id }, format: :json
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(club.id)
      expect(json["club_name"]).to eq("Alpha Club")
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
      it "creates a new Club" do
        expect {
          post :create, params: { club: valid_attributes }, format: :json
        }.to change(Club, :count).by(1)
      end

      it "returns ok status" do
        post :create, params: { club: valid_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns the created club as JSON" do
        post :create, params: { club: valid_attributes }, format: :json
        json = JSON.parse(response.body)
        expect(json["club_name"]).to eq("Beta Club")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Club).to receive(:save).and_return(false)
        post :create, params: { club: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the club" do
        patch :update, params: { id: club.id, club: { club_name: "Updated Club" } }, format: :json
        club.reload
        expect(club.club_name).to eq("Updated Club")
      end

      it "returns ok status" do
        patch :update, params: { id: club.id, club: { club_name: "Updated" } }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Club).to receive(:update).and_return(false)
        patch :update, params: { id: club.id, club: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST #merge_clubs" do
    let!(:other_club) { Club.create!(club_name: "Other Club") }

    it "merges the other club into the main club" do
      category = Category.create!(category_name: "Test")
      runner = Runner.create!(club: other_club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000)

      post :merge_clubs, params: { id: club.id, merged_club_id: other_club.id }
      expect(response).to have_http_status(:ok)
      expect(runner.reload.club_id).to eq(club.id)
    end

    it "destroys the merged club" do
      post :merge_clubs, params: { id: club.id, merged_club_id: other_club.id }
      expect { other_club.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the club" do
      # Ensure default club exists for the set_default_club callback
      Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" }
      expect {
        delete :destroy, params: { id: club.id }
      }.to change(Club, :count).by(-1)
    end

    it "redirects to clubs list (HTML)" do
      Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" }
      delete :destroy, params: { id: club.id }
      expect(response).to redirect_to(clubs_path)
    end

    it "returns no_content (JSON)" do
      Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" }
      delete :destroy, params: { id: club.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end
end
