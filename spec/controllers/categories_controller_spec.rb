# spec/controllers/categories_controller_spec.rb
require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  let!(:category) { Category.create!(category_name: "Pro", full_name: "Professional", points: 100, validaty_period: 12) }
  let(:valid_attributes) { { category_name: "Amateur", full_name: "Amateur League", points: 50, validaty_period: 6 } }
  let(:invalid_attributes) { { category_name: nil } }

  describe "GET #index" do
    it "returns a successful response (HTML)" do
      get :index
      expect(response).to be_successful
    end

    it "returns a successful JSON response" do
      get :index, format: :json
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.first).to have_key("category_name")
    end

    it "includes runners_count in JSON response" do
      get :index, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response.first).to have_key("runners_count")
    end

    context "with JSON format and scopes" do
      it "filters by search" do
        get :index, params: { search: "Pro" }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first["category_name"]).to eq("Pro")
      end

      it "filters by search (case-insensitive)" do
        get :index, params: { search: "pro" }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first["category_name"]).to eq("Pro")
      end

      it "returns empty when search does not match" do
        get :index, params: { search: "nonexistent" }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end

      it "filters by points range" do
        Category.create!(category_name: "Beginner", full_name: "Beginner", points: 10, validaty_period: 1)
        get :index, params: { points: { from: 80, to: 120 } }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first["category_name"]).to eq("Pro")
      end

      it "filters by validaty_period range" do
        Category.create!(category_name: "Short", full_name: "Short Period", points: 20, validaty_period: 1)
        get :index, params: { validaty_period: { from: 10, to: 15 } }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first["category_name"]).to eq("Pro")
      end

      it "sorts by category_name desc" do
        Category.create!(category_name: "Alpha", full_name: "Alpha", points: 10, validaty_period: 1)
        get :index, params: { sorting: { sort_by: "category_name", direction: "desc" } }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.first["category_name"]).to eq("Pro")
      end

      it "sorts by category_name asc" do
        Category.create!(category_name: "Alpha", full_name: "Alpha", points: 10, validaty_period: 1)
        get :index, params: { sorting: { sort_by: "category_name", direction: "asc" } }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.first["category_name"]).to eq("Alpha")
      end

      it "defaults to id sort for invalid sort column" do
        get :index, params: { sorting: { sort_by: "invalid_column", direction: "asc" } }, format: :json
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    it "returns a successful response (HTML)" do
      get :show, params: { id: category.id }
      expect(response).to be_successful
    end

    it "returns JSON data with correct attributes" do
      get :show, params: { id: category.id }, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response["id"]).to eq(category.id)
      expect(json_response["category_name"]).to eq("Pro")
      expect(json_response["full_name"]).to eq("Professional")
      expect(json_response["points"]).to eq(100.0)
      expect(json_response["validaty_period"]).to eq(12)
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params (JSON)" do
      it "creates a new Category" do
        expect {
          post :create, params: { category: valid_attributes }, format: :json
        }.to change(Category, :count).by(1)
      end

      it "renders a 200 OK status" do
        post :create, params: { category: valid_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns the created category as JSON" do
        post :create, params: { category: valid_attributes }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response["category_name"]).to eq("Amateur")
        expect(json_response["full_name"]).to eq("Amateur League")
        expect(json_response["points"]).to eq(50.0)
        expect(json_response["validaty_period"]).to eq(6)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        post :create, params: { category: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a new Category" do
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        expect {
          post :create, params: { category: invalid_attributes }, format: :json
        }.not_to change(Category, :count)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      let(:new_attributes) { { category_name: "Elite", full_name: "Elite League", points: 200 } }

      it "updates the requested category" do
        patch :update, params: { id: category.id, category: new_attributes }, format: :json
        category.reload
        expect(category.category_name).to eq("Elite")
        expect(category.full_name).to eq("Elite League")
        expect(category.points).to eq(200.0)
      end

      it "returns a 200 OK status" do
        patch :update, params: { id: category.id, category: new_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns the updated category as JSON" do
        patch :update, params: { id: category.id, category: new_attributes }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response["category_name"]).to eq("Elite")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content" do
        allow_any_instance_of(Category).to receive(:update).and_return(false)
        patch :update, params: { id: category.id, category: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested category" do
      expect {
        delete :destroy, params: { id: category.id }
      }.to change(Category, :count).by(-1)
    end

    it "redirects to the categories list (HTML)" do
      delete :destroy, params: { id: category.id }
      expect(response).to redirect_to(categories_path)
    end

    it "returns no_content (JSON)" do
      delete :destroy, params: { id: category.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end
end
