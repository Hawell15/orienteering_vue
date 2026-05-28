require "rails_helper"

RSpec.describe WreRaceReimporter do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:competition) do
    Competition.create!(
      competition_name: "Test WRE Race",
      date:             Date.new(2025, 6, 1),
      distance_type:    "Lungă",
      wre_id:           9999
    )
  end
  let!(:men_group)   { Group.create!(competition: competition, group_name: "M21E") }
  let!(:women_group) { Group.create!(competition: competition, group_name: "W21E") }
  let!(:reduction_group)     { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)         { |g| g.competition = competition; g.group_name = "REDUCTION" } }
  let!(:three_results_group) { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)              { |g| g.competition = competition; g.group_name = "THREE" } }
  let!(:title_group)         { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }

  let!(:runner_m) do
    Runner.create!(club: club, runner_name: "Roman", surname: "Ciobanu", gender: "M", yob: 1990, wre_id: 8458, best_category_id: 3)
  end
  let!(:runner_w) do
    Runner.create!(club: club, runner_name: "Victoria", surname: "Nosenco", gender: "W", yob: 1990, wre_id: 37897, best_category_id: 3)
  end
  let!(:membership_m) { Membership.create!(runner: runner_m, club: club) }
  let!(:membership_w) { Membership.create!(runner: runner_w, club: club) }

  let!(:result_m) do
    Result.create!(
      group:        men_group,
      membership:   membership_m,
      category_id:  4,
      place:        17,
      time:         8497,
      wre_points:   900,
      date:         competition.date,
      status:       Result::CONFIRMED
    )
  end
  let!(:result_w) do
    Result.create!(
      group:        women_group,
      membership:   membership_w,
      category_id:  4,
      place:        5,
      time:         6267,
      wre_points:   900,
      date:         competition.date,
      status:       Result::CONFIRMED
    )
  end

  let(:api_response) do
    [
      {
        "group" => "Men",
        "results" => [
          { "rank" => 17, "iofid" => 8458,  "points" => 956,  "result" => "141:37" },
          { "rank" => 1,  "iofid" => 18459, "points" => 1176, "result" => "81:19" }, # not in our DB
          { "rank" => 99999, "iofid" => 51996, "points" => 0, "result" => "NC" }     # DNF
        ]
      },
      {
        "group" => "Women",
        "results" => [
          { "rank" => 5, "iofid" => 37897, "points" => 1035, "result" => "104:27" }
        ]
      }
    ]
  end

  before do
    allow(Net::HTTP).to receive(:get).and_return(api_response.to_json)
  end

  describe "#call" do
    it "fetches the race API using the competition's wre_id" do
      expect(Net::HTTP).to receive(:get).with(URI("https://ranking.orienteering.org/api/race/9999")).and_return(api_response.to_json)
      WreRaceReimporter.new(competition).call
    end

    it "returns 0 and does nothing when competition has no wre_id" do
      competition.update!(wre_id: nil)
      expect(Net::HTTP).not_to receive(:get)
      expect(WreRaceReimporter.new(competition).call).to eq(0)
    end

    it "updates wre_points when points changed" do
      WreRaceReimporter.new(competition).call
      expect(result_m.reload.wre_points).to eq(956)
      expect(result_w.reload.wre_points).to eq(1035)
    end

    it "recomputes category_id from new points using the new band rule" do
      WreRaceReimporter.new(competition).call
      expect(result_m.reload.category_id).to eq(3) # 956 → 901..1050
      expect(result_w.reload.category_id).to eq(3) # 1035 → 901..1050
    end

    it "returns the number of updated results" do
      expect(WreRaceReimporter.new(competition).call).to eq(2)
    end

    it "does not touch results whose points did not change" do
      result_m.update!(wre_points: 956, category_id: 3)
      m_updated_at = result_m.reload.updated_at

      count = WreRaceReimporter.new(competition).call

      expect(count).to eq(1) # only women's result changed
      expect(result_m.reload.updated_at).to eq(m_updated_at)
    end

    it "skips entries with rank 0" do
      json = [ { "group" => "Men", "results" => [ { "rank" => 0, "iofid" => 8458, "points" => 1300 } ] } ]
      allow(Net::HTTP).to receive(:get).and_return(json.to_json)
      WreRaceReimporter.new(competition).call
      expect(result_m.reload.wre_points).to eq(900)
    end

    it "skips entries with rank 99999 (DNF/DQ)" do
      json = [ { "group" => "Men", "results" => [ { "rank" => 99_999, "iofid" => 8458, "points" => 0 } ] } ]
      allow(Net::HTTP).to receive(:get).and_return(json.to_json)
      WreRaceReimporter.new(competition).call
      expect(result_m.reload.wre_points).to eq(900)
    end

    it "skips runners not in our database" do
      expect { WreRaceReimporter.new(competition).call }.not_to raise_error
      expect(Runner.find_by(wre_id: 18459)).to be_nil
    end

    it "skips groups in the API response that don't match a group in this competition" do
      women_group.destroy!
      expect { WreRaceReimporter.new(competition).call }.not_to raise_error
      expect(result_m.reload.wre_points).to eq(956)
    end

    it "skips API groups other than Men/Women" do
      json = [ { "group" => "Juniors", "results" => [ { "rank" => 1, "iofid" => 8458, "points" => 1300 } ] } ]
      allow(Net::HTTP).to receive(:get).and_return(json.to_json)
      expect(WreRaceReimporter.new(competition).call).to eq(0)
      expect(result_m.reload.wre_points).to eq(900)
    end
  end
end
