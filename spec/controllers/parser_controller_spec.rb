require "rails_helper"

RSpec.describe ParserController, type: :controller do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "POST #file_results" do
    context "with a JSON file" do
      let(:json_data) do
        {
          "title" => "Uploaded Competition",
          "date" => "2025-06-01",
          "groups" => [
            {
              "name" => "M21",
              "distance_type" => "Sprint",
              "results" => [
                {
                  "place" => 1,
                  "time" => "15:30",
                  "runner_name" => "Ion Popescu",
                  "club" => "Test Club",
                  "date_of_birth" => "2000-01-01"
                }
              ]
            }
          ]
        }
      end

      let(:uploaded_file) do
        file = Tempfile.new([ "test", ".json" ])
        file.write(json_data.to_json)
        file.rewind
        Rack::Test::UploadedFile.new(file.path, "application/json", false, original_filename: "test.json")
      end

      it "creates a competition and redirects" do
        post :file_results, params: { path: uploaded_file }
        expect(response).to redirect_to(competition_url(Competition.last))
      end

      it "creates a competition record" do
        expect {
          post :file_results, params: { path: uploaded_file }
        }.to change(Competition, :count).by(1)
      end

      it "creates groups" do
        expect {
          post :file_results, params: { path: uploaded_file }
        }.to change(Group, :count).by_at_least(1)
      end

      it "creates runners" do
        expect {
          post :file_results, params: { path: uploaded_file }
        }.to change(Runner, :count).by_at_least(1)
      end
    end

    context "without a file" do
      it "does not raise" do
        get :file_results
        expect(response).to be_successful
      end
    end
  end

  describe "GET #iof_runners" do
    it "calls IofRunnersParser and redirects" do
      parser_instance = instance_double(IofRunnersParser)
      allow(IofRunnersParser).to receive(:new).and_return(parser_instance)
      allow(parser_instance).to receive(:convert)

      get :iof_runners
      expect(parser_instance).to have_received(:convert)
      expect(response).to redirect_to("#{runners_url}?wre=true")
    end
  end

  describe "GET #iof_results" do
    it "calls IofResultsParser and redirects" do
      parser_instance = instance_double(IofResultsParser)
      allow(IofResultsParser).to receive(:new).and_return(parser_instance)
      allow(parser_instance).to receive(:convert)

      get :iof_results
      expect(parser_instance).to have_received(:convert)
      expect(response).to redirect_to("#{runners_url}?wre=true")
    end
  end
end
