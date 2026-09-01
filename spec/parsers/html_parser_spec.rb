require "rails_helper"

RSpec.describe HtmlParser do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

  describe "#initialize" do
    it "sets return_data to competition" do
      parser = HtmlParser.new("/tmp/test.html")
      expect(parser.return_data).to eq("competition")
    end
  end

  describe "#extract_yob" do
    let(:parser) { HtmlParser.new("/tmp/test.html") }

    it "extracts year from date string" do
      expect(parser.extract_yob("2000-05-15")).to eq(2000)
    end

    it "returns 0 for nil" do
      expect(parser.extract_yob(nil)).to eq(0)
    end
  end

  describe "#check_result?" do
    let(:parser) { HtmlParser.new("/tmp/test.html") }

    it "returns true for any result" do
      expect(parser.check_result?("OK")).to be true
      expect(parser.check_result?(nil)).to be true
    end
  end

  describe "#distance_type" do
    let(:parser) { HtmlParser.new("/tmp/test.html") }

    it "extracts and strips description" do
      json = { "data" => { "description" => "  Sprint  " } }
      expect(parser.distance_type(json)).to eq("Sprint")
    end
  end

  describe "#extract_runner" do
    let(:parser) { HtmlParser.new("/tmp/test.html") }

    it "builds runner hash" do
      runner_data = {
        "surname" => "Ion",
        "name" => "Popescu",
        "birth_date" => "2000-01-01",
        "organization_id" => 1
      }
      result = parser.extract_runner(runner_data, "M", "Club A")
      expect(result[:runner_name]).to eq("Ion")
      expect(result[:surname]).to eq("Popescu")
      expect(result[:yob]).to eq(2000)
      expect(result[:gender]).to eq("M")
      expect(result[:club]).to eq("Club A")
    end

    it "compacts nil values" do
      runner_data = { "surname" => "A", "name" => "B", "birth_date" => nil }
      result = parser.extract_runner(runner_data, "M", nil)
      expect(result).not_to have_value(nil)
    end
  end

  describe "#extract_competition_details" do
    let(:parser) { HtmlParser.new("/tmp/test.html") }

    it "sets hash with competition data" do
      json = {
        "data" => {
          "title" => "Test Race",
          "start_datetime" => "2025-06-01T10:00:00",
          "description" => "Sprint"
        },
        "groups" => [],
        "persons" => [],
        "results" => [],
        "organizations" => []
      }
      parser.extract_competition_details(json)
      expect(parser.hash[:competition_name]).to eq("Test Race")
      expect(parser.hash[:distance_type]).to eq("Sprint")
      expect(parser.hash[:groups]).to eq([])
    end
  end

  describe "#extract_results" do
    let(:parser) { HtmlParser.new("/tmp/test.html") }

    it "extracts results matching group" do
      json = {
        "persons" => [
          { "id" => 1, "group_id" => 10, "surname" => "Ion", "name" => "Pop", "birth_date" => "2000-01-01", "organization_id" => 1 }
        ],
        "results" => [
          { "person_id" => 1, "place" => 1, "result" => "OK", "result_msec" => 930000 }
        ],
        "organizations" => [
          { "id" => 1, "name" => "Club A" }
        ]
      }
      group = { "id" => 10 }
      results = parser.extract_results(json, group, "M")
      expect(results.compact.length).to eq(1)
      expect(results.compact.first[:place]).to eq(1)
      expect(results.compact.first[:time]).to eq(930)
      expect(results.compact.first[:membership]).to eq("Club A")
    end

    it "skips results with place < 1" do
      json = {
        "persons" => [ { "id" => 1, "group_id" => 10, "surname" => "A", "name" => "B", "birth_date" => nil, "organization_id" => 1 } ],
        "results" => [ { "person_id" => 1, "place" => 0, "result" => "OK", "result_msec" => 1000 } ],
        "organizations" => [ { "id" => 1, "name" => "C" } ]
      }
      group = { "id" => 10 }
      results = parser.extract_results(json, group, "M")
      expect(results.compact).to be_empty
    end

    it "skips when result is nil" do
      json = {
        "persons" => [ { "id" => 1, "group_id" => 10, "surname" => "A", "name" => "B", "birth_date" => nil, "organization_id" => 1 } ],
        "results" => [],
        "organizations" => [ { "id" => 1, "name" => "C" } ]
      }
      group = { "id" => 10 }
      results = parser.extract_results(json, group, "M")
      expect(results.compact).to be_empty
    end
  end
end
