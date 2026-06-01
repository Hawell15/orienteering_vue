require "rails_helper"

RSpec.describe RelayJsonParser do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

  let(:json_data) do
    {
      "title" => "Cupa Relay",
      "date"  => "02.05.2026",
      "groups" => [
        {
          "name" => "M21",
          "distance_type" => "эстафета",
          "results" => [
            { "place" => "1", "time" => "00:40.47", "runner_name" => "Babici Artiom",   "runner_id" => "0", "club" => "ȘS Tiraspol", "date_of_birth" => "10.05.2007" },
            { "place" => "1", "time" => "00:29.57", "runner_name" => "Fomiciov Anatolii", "runner_id" => "0", "club" => "ȘS Tiraspol", "date_of_birth" => "26.04.1997" },
            { "place" => "1", "time" => "00:34.53", "runner_name" => "Fomiciov Ivan",   "runner_id" => "0", "club" => "ȘS Tiraspol", "date_of_birth" => "17.01.1994" },
            { "place" => "2", "time" => "00:38.52", "runner_name" => "Ciobanu Roman",   "runner_id" => "0", "club" => "CS Galata",  "date_of_birth" => "15.02.1991" },
            { "place" => "2", "time" => "00:36.02", "runner_name" => "Fala Sergiu",     "runner_id" => "0", "club" => "CS Galata",  "date_of_birth" => "27.05.1993" },
            { "place" => "2", "time" => "00:35.23", "runner_name" => "Golovei Andrei",  "runner_id" => "0", "club" => "CS Galata",  "date_of_birth" => "12.12.1993" }
          ]
        }
      ]
    }
  end

  let(:json_path) do
    file = Tempfile.new([ "test_relay", ".json" ])
    file.write(json_data.to_json)
    file.rewind
    file.path
  end

  describe "#initialize" do
    it "defaults relay_type to classic" do
      parser = RelayJsonParser.new(json_path)
      expect(parser.instance_variable_get(:@relay_type)).to eq("classic")
    end

    it "accepts a relay_type kwarg" do
      parser = RelayJsonParser.new(json_path, relay_type: "sprint")
      expect(parser.instance_variable_get(:@relay_type)).to eq("sprint")
    end
  end

  describe "#distance_type" do
    it "returns Ștafetă clasică by default" do
      parser = RelayJsonParser.new(json_path)
      expect(parser.distance_type(nil)).to eq("Ștafetă clasică")
    end

    it "returns Ștafetă sprint when relay_type is sprint" do
      parser = RelayJsonParser.new(json_path, relay_type: "sprint")
      expect(parser.distance_type(nil)).to eq("Ștafetă sprint")
    end
  end

  describe "#extract_groups_details" do
    let(:parser) { RelayJsonParser.new(json_path) }

    it "groups legs by place into team payloads" do
      groups = parser.extract_groups_details(json_data["groups"])
      expect(groups.length).to eq(1)
      relays = groups.first[:results]
      expect(relays.length).to eq(2)
      expect(relays.first[:place]).to eq(1)
      expect(relays.first[:legs].length).to eq(3)
      expect(relays.first[:team]).to eq("ȘS Tiraspol")
    end

    it "sums leg times into the team total" do
      groups = parser.extract_groups_details(json_data["groups"])
      relay1 = groups.first[:results].find { |r| r[:place] == 1 }
      total  = parser.send(:convert_time, "00:40.47") +
               parser.send(:convert_time, "00:29.57") +
               parser.send(:convert_time, "00:34.53")
      expect(relay1[:time]).to eq(total)
    end

    it "skips rows with blank runner_name or zero place" do
      data = json_data.deep_dup
      data["groups"].first["results"] << { "place" => "0", "time" => "00:00.00", "runner_name" => "", "club" => "X", "date_of_birth" => "01.01.2000" }
      file = Tempfile.new([ "extra", ".json" ])
      file.write(data.to_json); file.rewind
      groups = RelayJsonParser.new(file.path).extract_groups_details(data["groups"])
      expect(groups.first[:results].length).to eq(2) # still just two teams
    end
  end

  describe "#convert" do
    it "creates competition, group, RelayResults and leg Results in order" do
      result = RelayJsonParser.new(json_path).convert

      expect(result).to be_a(Competition)
      expect(result.competition_name).to eq("Cupa Relay")
      expect(result.distance_type).to eq("Ștafetă clasică")
      expect(result.date).to eq(Date.new(2026, 5, 2))

      group = Group.find_by(competition: result, group_name: "M21")
      expect(group).to be_present

      relays = RelayResult.where(group: group).order(:place)
      expect(relays.size).to eq(2)
      expect(relays.first.place).to eq(1)
      expect(relays.first.team).to eq("ȘS Tiraspol")
      expect(relays.first.results_id.size).to eq(3)
      expect(relays.first.category_id).to eq(Category::NO_CATEGORY_ID)

      legs = relays.first.results_id.map { |id| Result.find(id) }
      expect(legs.first.membership.runner.runner_name).to eq("Babici")
      expect(legs.first.membership.runner.surname).to eq("Artiom")
    end

    it "uses the supplied relay_type for distance_type" do
      result = RelayJsonParser.new(json_path, relay_type: "sprint").convert
      expect(result.distance_type).to eq("Ștafetă sprint")
    end

    it "skips teams whose leg count doesn't match the relay type" do
      # Classic requires 3 legs; remove one from team 1 so it has 2.
      data = json_data.deep_dup
      data["groups"].first["results"].shift
      file = Tempfile.new([ "short", ".json" ])
      file.write(data.to_json); file.rewind

      RelayJsonParser.new(file.path).convert
      group = Group.find_by(group_name: "M21")
      expect(RelayResult.where(group: group).pluck(:place)).to eq([ 2 ])
    end
  end
end
