require "rails_helper"

RSpec.describe RunnersController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  before { sign_in admin_user }

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

  describe "authorization on write actions" do
    let(:non_admin) { FactoryBot.create(:user) }

    context "when signed out" do
      before { sign_out admin_user }

      it "redirects HTML POST #create to root" do
        post :create, params: { runner: valid_attributes }
        expect(response).to redirect_to(root_path)
      end

      it "returns 403 for JSON POST #create" do
        post :create, params: { runner: valid_attributes }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when signed in as non-admin" do
      before { sign_in non_admin }

      it "returns 403 for JSON DELETE #destroy" do
        delete :destroy, params: { id: runner.id }, format: :json
        expect(response).to have_http_status(:forbidden)
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

  describe "license bulk-edit" do
    let!(:with_license)    { Runner.create!(club: club, category: category, best_category: category, runner_name: "Has", surname: "L", gender: "M", yob: 2000, license: true) }
    let!(:without_license) { Runner.create!(club: club, category: category, best_category: category, runner_name: "No",  surname: "L", gender: "M", yob: 2000, license: false) }

    describe "GET #license" do
      it "returns all runners when license filter = all" do
        get :license, format: :json
        ids = JSON.parse(response.body).map { |r| r["id"] }
        expect(ids).to include(runner.id, with_license.id, without_license.id)
      end

      it "filters by license=true" do
        get :license, params: { license: "true" }, format: :json
        ids = JSON.parse(response.body).map { |r| r["id"] }
        expect(ids).to include(with_license.id)
        expect(ids).not_to include(without_license.id)
      end

      it "filters by license=false" do
        get :license, params: { license: "false" }, format: :json
        ids = JSON.parse(response.body).map { |r| r["id"] }
        expect(ids).to include(without_license.id)
        expect(ids).not_to include(with_license.id)
      end

      it "is accessible to non-admin users (read-only)" do
        sign_out admin_user
        sign_in FactoryBot.create(:user)
        get :license, format: :json
        expect(response).to be_successful
      end

      it "is accessible when signed out" do
        sign_out admin_user
        get :license, format: :json
        expect(response).to be_successful
      end
    end

    describe "PATCH #bulk_update_license" do
      it "applies the supplied license values to the named runners" do
        patch :bulk_update_license,
              params: { runners: [
                { id: with_license.id,    license: false },
                { id: without_license.id, license: true  }
              ] },
              format: :json

        expect(response).to have_http_status(:ok)
        expect(with_license.reload.license).to be false
        expect(without_license.reload.license).to be true
      end

      it "accepts string boolean values from the form" do
        patch :bulk_update_license,
              params: { runners: [ { id: with_license.id, license: "0" } ] },
              format: :json
        expect(with_license.reload.license).to be false
      end

      it "does not touch runners not present in the payload" do
        patch :bulk_update_license,
              params: { runners: [ { id: with_license.id, license: false } ] },
              format: :json
        expect(without_license.reload.license).to be false # unchanged from initial
      end

      it "is forbidden for non-admin users" do
        sign_out admin_user
        sign_in FactoryBot.create(:user)
        patch :bulk_update_license,
              params: { runners: [ { id: with_license.id, license: false } ] },
              format: :json
        expect(response).to have_http_status(:forbidden)
        expect(with_license.reload.license).to be true # unchanged
      end
    end
  end

  describe "GET #relays" do
    let!(:relay_competition) do
      Competition.create!(
        competition_name: "Cupa Ștafetă",
        date:             Date.new(2026, 5, 2),
        distance_type:    "Ștafetă clasică",
        country:          "Moldova"
      )
    end
    let!(:relay_group) { Group.create!(competition: relay_competition, group_name: "M21S") }

    def make_leg(r)
      m = Membership.find_or_create_by!(runner: r, club: club)
      Result.create!(
        group: relay_group, membership: m, category_id: Category::NO_CATEGORY_ID,
        date: relay_competition.date, time: 1800, place: 1, status: Result::CONFIRMED,
        skip_processing: true
      )
    end

    it "returns an empty array when the runner has no relay participation" do
      get :relays, params: { id: runner.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "surfaces leg metadata (team, place, leg_index/count, times, competition info)" do
      teammate1 = Runner.create!(club: club, category: category, best_category: category, runner_name: "T1", surname: "X", gender: "M", yob: 2000)
      teammate2 = Runner.create!(club: club, category: category, best_category: category, runner_name: "T2", surname: "X", gender: "M", yob: 2000)

      leg1 = make_leg(teammate1)
      leg2 = make_leg(runner)
      leg3 = make_leg(teammate2)

      RelayResult.create!(
        group: relay_group, category: category, place: 1, time: 5400,
        team: "MDA-1", date: relay_competition.date,
        results_id: [ leg1.id, leg2.id, leg3.id ]
      )

      get :relays, params: { id: runner.id }, format: :json

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      row = json.first
      expect(row["team"]).to eq("MDA-1")
      expect(row["place"]).to eq(1)
      expect(row["leg_index"]).to eq(2)
      expect(row["leg_count"]).to eq(3)
      expect(row["leg_time"]).to eq(1800)
      expect(row["relay_time"]).to eq(5400)
      expect(row["group_name"]).to eq("M21S")
      expect(row["competition_id"]).to eq(relay_competition.id)
      expect(row["competition_name"]).to eq("Cupa Ștafetă")
    end

    it "lists multiple relays ordered by competition date (newest first)" do
      older_competition = Competition.create!(competition_name: "Old", date: Date.new(2025, 4, 1), distance_type: "Ștafetă clasică")
      older_group = Group.create!(competition: older_competition, group_name: "M21S")

      newer_leg = make_leg(runner)
      RelayResult.create!(group: relay_group, category: category, place: 2, time: 5400,
                          team: "NEW", date: relay_competition.date,
                          results_id: [ newer_leg.id, make_leg(Runner.create!(club: club, category: category, best_category: category, runner_name: "x1", surname: "x", gender: "M", yob: 2000)).id,
                                        make_leg(Runner.create!(club: club, category: category, best_category: category, runner_name: "x2", surname: "x", gender: "M", yob: 2000)).id ])

      m = Membership.find_or_create_by!(runner: runner, club: club)
      older_leg = Result.create!(group: older_group, membership: m, category_id: Category::NO_CATEGORY_ID,
                                 date: older_competition.date, time: 1800, place: 1, status: Result::CONFIRMED, skip_processing: true)
      o1 = Result.create!(group: older_group, membership: Membership.create!(runner: Runner.create!(club: club, category: category, best_category: category, runner_name: "o1", surname: "x", gender: "M", yob: 2000), club: club),
                          category_id: Category::NO_CATEGORY_ID, date: older_competition.date, time: 1800, place: 1, status: Result::CONFIRMED, skip_processing: true)
      o2 = Result.create!(group: older_group, membership: Membership.create!(runner: Runner.create!(club: club, category: category, best_category: category, runner_name: "o2", surname: "x", gender: "M", yob: 2000), club: club),
                          category_id: Category::NO_CATEGORY_ID, date: older_competition.date, time: 1800, place: 1, status: Result::CONFIRMED, skip_processing: true)
      RelayResult.create!(group: older_group, category: category, place: 5, time: 5400,
                          team: "OLD", date: older_competition.date,
                          results_id: [ older_leg.id, o1.id, o2.id ])

      get :relays, params: { id: runner.id }, format: :json
      json = JSON.parse(response.body)
      expect(json.map { |r| r["team"] }).to eq([ "NEW", "OLD" ])
    end
  end
end
