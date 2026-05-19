require "rails_helper"

RSpec.describe IofResultsParser do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

  describe "#initialize" do
    it "sets default attributes" do
      parser = IofResultsParser.new
      expect(parser.hash).to eq({})
      expect(parser.return_data).to be_nil
      expect(parser.return_result).to be_nil
    end
  end

  describe "#get_wre_category" do
    let(:parser) { IofResultsParser.new }

    it "returns 4 for 700-900 points" do
      expect(parser.get_wre_category(700)).to eq(4)
      expect(parser.get_wre_category(900)).to eq(4)
    end

    it "returns 3 for 901-1050 points" do
      expect(parser.get_wre_category(901)).to eq(3)
      expect(parser.get_wre_category(1050)).to eq(3)
    end

    it "returns 2 for 1051-1250 points" do
      expect(parser.get_wre_category(1051)).to eq(2)
      expect(parser.get_wre_category(1250)).to eq(2)
    end

    it "returns 1 for 1251-1500 points" do
      expect(parser.get_wre_category(1251)).to eq(1)
      expect(parser.get_wre_category(1500)).to eq(1)
    end

    it "returns 10 for points below 700" do
      expect(parser.get_wre_category(500)).to eq(10)
    end

    it "returns 10 for points above 1500" do
      expect(parser.get_wre_category(1600)).to eq(10)
    end
  end

  describe "#extract_competition_details" do
    let(:parser) { IofResultsParser.new }

    let(:json_data) do
      [
        {
          "raceDate" => "2025-06-01",
          "raceName" => "WRE Race",
          "raceId" => 123,
          "raceFormat" => "F",
          "gender" => "M",
          "rank" => 1,
          "result" => "45:30",
          "points" => 950,
          "runner_id" => 1,
          "runner_wre_id" => 100
        },
        {
          "raceDate" => "2025-06-01",
          "raceName" => "WRE Race",
          "raceId" => 123,
          "raceFormat" => "F",
          "gender" => "W",
          "rank" => 1,
          "result" => "50:00",
          "points" => 800,
          "runner_id" => 2,
          "runner_wre_id" => 200
        }
      ]
    end

    it "groups results by competition" do
      parser.extract_competition_details(json_data)
      expect(parser.hash.length).to eq(1)
      expect(parser.hash.first[:competition_name]).to eq("WRE Race")
      expect(parser.hash.first[:wre_id]).to eq(123)
    end

    it "creates groups per gender" do
      parser.extract_competition_details(json_data)
      groups = parser.hash.first[:groups]
      expect(groups.length).to eq(2)
    end
  end

  describe "#extract_results" do
    let(:parser) { IofResultsParser.new }

    it "extracts result data" do
      json = [
        { "rank" => 1, "result" => "30:00", "points" => 950, "runner_id" => 1 }
      ]
      results = parser.extract_results(json, Date.new(2025, 6, 1))
      expect(results.length).to eq(1)
      expect(results.first[:place]).to eq(1)
      expect(results.first[:time]).to eq(30 * 60)
      expect(results.first[:wre_points]).to eq(950)
      expect(results.first[:category_id]).to eq(3) # 901-1050
    end

    it "skips results with rank 0" do
      json = [
        { "rank" => 0, "result" => "30:00", "points" => 500, "runner_id" => 1 }
      ]
      results = parser.extract_results(json, Date.new(2025, 6, 1))
      expect(results).to be_empty
    end
  end

  describe "#get_data" do
    let(:parser) { IofResultsParser.new }

    it "returns empty when no runners have wre_id" do
      expect(parser.get_data).to be_empty
    end
  end
end
