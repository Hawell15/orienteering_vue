# spec/controllers/categories_controller_spec.rb
require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  let!(:category) { Category.create!(category_name: "Pro", full_name: "Professional", points: 100, validaty_period: 12) }
  let(:valid_attributes) { { category_name: "Amateur", full_name: "Amateur League", points: 50, validaty_period: 6 } }
  let(:invalid_attributes) { { category_name: nil } }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    context "with JSON format and scopes" do
      it "filters by search" do
        get :index, params: { search: "Pro" }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.first["category_name"]).to eq("Pro")
      end

      it "filters by points range" do
        get :index, params: { points: { from: 80, to: 120 } }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
      end

      it "sorts by category_name desc" do
        Category.create!(category_name: "Alpha", full_name: "Alpha", points: 10, validaty_period: 1)
        get :index, params: { sorting: { sort_by: "category_name", direction: "desc" } }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.first["category_name"]).to eq("Pro")
      end
    end
  end

  describe "GET #show" do
    it "returns a successful response" do
      get :show, params: { id: category.id }
      expect(response).to be_successful
    end

    it "returns JSON data" do
      get :show, params: { id: category.id }, format: :json
      expect(JSON.parse(response.body)["id"]).to eq(category.id)
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
    end

    context "with invalid params" do
      it "returns unprocessable_entity" do
        # Assuming category_name is required in the model
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        post :create, params: { category: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      let(:new_attributes) { { category_name: "Elite" } }

      it "updates the requested category" do
        patch :update, params: { id: category.id, category: new_attributes }, format: :json
        category.reload
        expect(category.category_name).to eq("Elite")
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
