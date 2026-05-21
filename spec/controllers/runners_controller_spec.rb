require "rails_helper"

RSpec.describe RunnersController, type: :controller do
  let!(:category) { Category.create!(category_name: "Pro", points: 100, validaty_period: 2) }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category" } }
  let!(:club) { Club.create!(club_name: "Test Club") }
  let!(:runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000) }
  let(:valid_attributes) { { runner_name: "Jane", surname: "Smith", gender: "W", yob: 2001, club_id: club.id, category_id: category.id, best_category_id: category.id } }
  let(:invalid_attributes) { { runner_name: nil } }

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

    it "includes full_name, club_name, and category_name" do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json.first).to have_key("full_name")
      expect(json.first).to have_key("club_name")
      expect(json.first).to have_key("category_name")
    end

    context "with scopes" do
      it "filters by club" do
        other_club = Club.create!(club_name: "Other")
        Runner.create!(club: other_club, category: category, best_category: category, runner_name: "X", surname: "Y", gender: "M", yob: 2000)
        get :index, params: { club: club.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["club_name"]).to eq("Test Club")
      end

      it "filters by category" do
        get :index, params: { category: category.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "filters by gender" do
        Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "W", yob: 2001)
        get :index, params: { gender: "M" }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end

      it "sorts by yob" do
        Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 1990)
        get :index, params: { sorting: { sort_by: "yob", direction: "asc" } }, format: :json
        json = JSON.parse(response.body)
        expect(json.first["yob"]).to eq(1990)
      end

      it "filters by yob range" do
        Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 1980)
        get :index, params: { yob: { from: 1995, to: 2005 } }, format: :json
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["yob"]).to eq(2000)
      end
    end
  end

  describe "GET #show" do
    it "returns a successful HTML response" do
      get :show, params: { id: runner.id }
      expect(response).to be_successful
    end

    it "returns JSON with associations" do
      get :show, params: { id: runner.id }, format: :json
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(runner.id)
      expect(json["runner_name"]).to eq("John")
      expect(json["category"]).to be_present
      expect(json["club"]).to be_present
      expect(json["best_category"]).to be_present
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
      it "creates a new Runner" do
        expect {
          post :create, params: { runner: valid_attributes }, format: :json
        }.to change(Runner, :count).by(1)
      end

      it "returns ok status" do
        post :create, params: { runner: valid_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns the created runner with index_base_query format" do
        post :create, params: { runner: valid_attributes }, format: :json
        json = JSON.parse(response.body)
        expect(json["runner_name"]).to eq("Jane")
        expect(json).to have_key("full_name")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Runner).to receive(:save).and_return(false)
        post :create, params: { runner: valid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the runner" do
        patch :update, params: { id: runner.id, runner: { runner_name: "Updated" } }, format: :json
        runner.reload
        expect(runner.runner_name).to eq("Updated")
      end

      it "returns ok status" do
        patch :update, params: { id: runner.id, runner: { runner_name: "Updated" } }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Runner).to receive(:update).and_return(false)
        patch :update, params: { id: runner.id, runner: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the runner" do
      expect {
        delete :destroy, params: { id: runner.id }
      }.to change(Runner, :count).by(-1)
    end

    it "redirects to runners list (HTML)" do
      delete :destroy, params: { id: runner.id }
      expect(response).to redirect_to(runners_path)
    end

    it "returns no_content (JSON)" do
      delete :destroy, params: { id: runner.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET #filters" do
    it "returns clubs, categories, and genders" do
      get :filters, format: :json
      json = JSON.parse(response.body)
      expect(json).to have_key("clubs")
      expect(json).to have_key("categories")
      expect(json).to have_key("genders")
    end
  end

  describe "POST #merge_runners" do
    let!(:other_runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "Other", surname: "Z", gender: "M", yob: 1999) }

    it "calls merge_from! with permitted attributes and destroys the merged runner" do
      post :merge_runners,
           params: { id: runner.id, merged_runner_id: other_runner.id, runner: { runner_name: "Merged" } },
           format: :json

      expect(response).to have_http_status(:ok)
      expect(runner.reload.runner_name).to eq("Merged")
      expect { other_runner.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "succeeds when runner params are omitted" do
      post :merge_runners,
           params: { id: runner.id, merged_runner_id: other_runner.id },
           format: :json

      expect(response).to have_http_status(:ok)
      expect { other_runner.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
