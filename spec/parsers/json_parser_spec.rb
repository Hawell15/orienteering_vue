require "rails_helper"

RSpec.describe JsonParser do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

  let(:json_data) do
    {
      "title" => "Test Competition",
      "date" => "01.06.2025",
      "groups" => [
        {
          "name" => "M21",
          "distance_type" => "Sprint",
          "results" => [
            {
              "place" => 1,
              "time" => "15:30",
              "runner_name" => "Ion Popescu",
              "club" => "Club A",
              "date_of_birth" => "2000-01-01"
            },
            {
              "place" => 2,
              "time" => "16:00",
              "runner_name" => "Vasile Munteanu",
              "club" => "Club B",
              "date_of_birth" => "1999-05-15"
            }
          ]
        }
      ]
    }
  end

  let(:json_path) do
    file = Tempfile.new([ "test", ".json" ])
    file.write(json_data.to_json)
    file.rewind
    file.path
  end

  describe "#initialize" do
    it "sets return_data to competition" do
      parser = JsonParser.new("/tmp/test.json")
      expect(parser.return_data).to eq("competition")
    end
  end

  describe "#extract_competition_details" do
    it "extracts competition info from json" do
      parser = JsonParser.new(json_path)
      parser.extract_competition_details(json_data)
      expect(parser.hash[:competition_name]).to eq("Test Competition")
      expect(parser.hash[:distance_type]).to eq("Sprint")
      expect(parser.hash[:groups]).to be_an(Array)
      expect(parser.hash[:groups].length).to eq(1)
    end
  end

  describe "#extract_groups_details" do
    it "extracts group names and results" do
      parser = JsonParser.new(json_path)
      groups = parser.extract_groups_details(json_data["groups"])
      expect(groups.first[:group_name]).to eq("M21")
      expect(groups.first[:results].length).to eq(2)
    end
  end

  describe "#extract_results" do
    it "extracts result details" do
      parser = JsonParser.new(json_path)
      results = parser.extract_results(json_data["groups"].first["results"], "M")
      expect(results.first[:place]).to eq(1)
      expect(results.first[:time]).to eq(15 * 60 + 30)
      expect(results.first[:membership]).to eq("Club A")
      expect(results.first[:category_id]).to eq(Category::NO_CATEGORY_ID)
    end

    it "skips blank results" do
      results_data = [ nil, { "place" => 1, "time" => "10:00", "runner_name" => "A B", "club" => "C", "date_of_birth" => "2000-01-01" } ]
      parser = JsonParser.new(json_path)
      results = parser.extract_results(results_data, "M")
      expect(results.compact.length).to eq(1)
    end
  end

  describe "#extract_runner" do
    it "splits runner_name into runner_name and surname" do
      parser = JsonParser.new(json_path)
      result = { "runner_name" => "Ion Popescu", "club" => "Club A", "date_of_birth" => "2000-01-01" }
      runner = parser.extract_runner(result, "M")
      expect(runner[:runner_name]).to eq("Ion")
      expect(runner[:surname]).to eq("Popescu")
      expect(runner[:gender]).to eq("M")
      expect(runner[:yob]).to eq(2000)
    end
  end

  describe "#extract_yob" do
    it "extracts year from date string" do
      parser = JsonParser.new(json_path)
      expect(parser.extract_yob("2000-01-01")).to eq(2000)
    end

    it "returns 0 for Null" do
      parser = JsonParser.new(json_path)
      expect(parser.extract_yob("Null")).to eq(0)
    end
  end

  describe "#convert" do
    it "creates competition, groups, runners, and results" do
      parser = JsonParser.new(json_path)
      result = parser.convert
      expect(result).to be_a(Competition)
      expect(result.competition_name).to eq("Test Competition")
      expect(Group.where(competition: result).count).to be >= 1
    end
  end
end
