require "rails_helper"

RSpec.describe IofRunnersParser do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

  describe "#initialize" do
    it "sets default attributes" do
      parser = IofRunnersParser.new
      expect(parser.hash).to eq({})
      expect(parser.return_data).to be_nil
    end
  end

  describe "#extract_runner_details" do
    let(:parser) { IofRunnersParser.new }

    it "extracts runner details from hash" do
      runner_data = {
        "Last Name" => "Popescu",
        "First Name" => "Ion",
        "yob" => 2000,
        "Gender" => "MEN",
        "IOF ID" => 12345,
        "WRS points" => "800",
        "WRS Position" => "50",
        "Sprint WRS points" => "750",
        "Sprint WRS Position" => "60"
      }
      result = parser.extract_runner_details(runner_data)
      expect(result[:runner_name]).to eq("Popescu")
      expect(result[:surname]).to eq("Ion")
      expect(result[:yob]).to eq(2000)
      expect(result[:gender]).to eq("M")
      expect(result[:wre_id]).to eq(12345)
      expect(result[:club_id]).to eq(1)
      expect(result[:forest_wre_rang]).to eq("800")
      expect(result[:sprint_wre_rang]).to eq("750")
    end

    it "handles WOMEN gender" do
      runner_data = { "Last Name" => "Munteanu", "First Name" => "Maria", "yob" => 2001, "Gender" => "WOMEN", "IOF ID" => 99 }
      result = parser.extract_runner_details(runner_data)
      expect(result[:gender]).to eq("W")
    end

    it "compacts nil values" do
      runner_data = { "Last Name" => "Test", "First Name" => "A", "yob" => 0, "Gender" => "MEN", "IOF ID" => 1 }
      result = parser.extract_runner_details(runner_data)
      expect(result).not_to have_value(nil)
    end
  end

  describe "#merge_data" do
    let(:parser) { IofRunnersParser.new }

    it "merges sprint data into forest data by IOF ID" do
      forest = [ { "IOF ID" => "1", "WRS points" => "800", "First Name" => "Ion" } ]
      sprint = [ { "IOF ID" => "1", "Sprint WRS points" => "750", "First Name" => "Ion" } ]
      result = parser.merge_data(forest, sprint)
      expect(result.length).to eq(1)
      expect(result.first["WRS points"]).to eq("800")
      expect(result.first["Sprint WRS points"]).to eq("750")
    end

    it "adds new runners from sprint data" do
      forest = [ { "IOF ID" => "1", "First Name" => "Ion" } ]
      sprint = [ { "IOF ID" => "2", "First Name" => "Maria" } ]
      result = parser.merge_data(forest, sprint)
      expect(result.length).to eq(2)
    end
  end

  describe "#update_wre_data" do
    let(:parser) { IofRunnersParser.new }

    it "updates runner WRE fields" do
      category = Category.find_or_create_by!(id: 5) { |c| c.category_name = "II" }
      runner = Runner.create!(club: club, category: no_category, best_category: no_category, runner_name: "A", surname: "B", gender: "M", yob: 2000)
      parser.update_wre_data(runner, { wre_id: 999, sprint_wre_rang: 100, forest_wre_rang: 200, sprint_wre_place: 10, forest_wre_place: 20 })
      runner.reload
      expect(runner.wre_id).to eq(999)
      expect(runner.sprint_wre_rang).to eq(100)
      expect(runner.forest_wre_rang).to eq(200)
    end
  end

  describe "#add_runners" do
    let(:parser) { IofRunnersParser.new }

    it "creates runner and updates wre data" do
      hash = {
        runner_name: "Ion", surname: "Popescu", yob: 2000, gender: "M",
        club_id: club.id, wre_id: 555,
        sprint_wre_rang: 100, forest_wre_rang: 200,
        sprint_wre_place: 10, forest_wre_place: 20
      }
      runner = parser.add_runners(hash)
      expect(runner).to be_a(Runner)
      expect(runner.wre_id).to eq(555)
      expect(runner.sprint_wre_rang).to eq(100)
    end
  end

  describe "#extract_competition_details" do
    let(:parser) { IofRunnersParser.new }

    it "sets hash with groups key" do
      allow(parser).to receive(:extract_groups_details).and_return([])
      parser.extract_competition_details
      expect(parser.hash).to have_key(:groups)
    end
  end

  describe "#extract_groups_details" do
    let(:parser) { IofRunnersParser.new }

    it "returns array with results key" do
      allow(parser).to receive(:extract_results).and_return([])
      result = parser.extract_groups_details
      expect(result).to eq([ results: [] ])
    end
  end
end
