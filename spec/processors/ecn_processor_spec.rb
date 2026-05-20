require "rails_helper"

RSpec.describe EcnProcessor do
  let!(:competition) { Competition.create!(competition_name: "Test", date: Date.new(2025, 6, 1), distance_type: "Sprint") }
  let!(:category) { Category.create!(category_name: "Test") }
  let!(:club) { Club.create!(club_name: "Test Club") }
  let!(:runner1) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000) }
  let!(:runner2) { Runner.create!(club: club, category: category, best_category: category, runner_name: "C", surname: "D", gender: "M", yob: 2001) }
  let!(:membership1) { Membership.create!(runner: runner1, club: club) }
  let!(:membership2) { Membership.create!(runner: runner2, club: club) }

  describe ".get_ecn_points" do
    it "calculates ecn points correctly" do
      # formula: (coeficient * winner_time / time * 100).round(2)
      result = EcnProcessor.send(:get_ecn_points, 1000, 1.5, 1200)
      expect(result).to eq((1.5 * 1000 / 1200.0 * 100).round(2))
    end

    it "returns 100 * coeficient for the winner (same time)" do
      result = EcnProcessor.send(:get_ecn_points, 1000, 1.5, 1000)
      expect(result).to eq(150.0)
    end

    it "returns less points for slower times" do
      winner_points = EcnProcessor.send(:get_ecn_points, 1000, 1.0, 1000)
      slower_points = EcnProcessor.send(:get_ecn_points, 1000, 1.0, 1500)
      expect(slower_points).to be < winner_points
    end
  end

  describe ".group_processor" do
    let!(:group) { Group.create!(competition: competition, group_name: "M21", ecn_coeficient: 1.5) }
    let!(:result1) { Result.create!(group: group, membership: membership1, category: category, date: Date.today, place: 1, time: 1000) }
    let!(:result2) { Result.create!(group: group, membership: membership2, category: category, date: Date.today, place: 2, time: 1200) }

    it "calculates ecn_points for all results with valid times" do
      EcnProcessor.group_processor(group)
      result1.reload
      result2.reload
      expect(result1.ecn_points).to eq(150.0)
      expect(result2.ecn_points).to eq((1.5 * 1000 / 1200.0 * 100).round(2))
    end

    it "gives the winner the highest points" do
      EcnProcessor.group_processor(group)
      expect(result1.reload.ecn_points).to be > result2.reload.ecn_points
    end

    it "skips results with nil time" do
      no_time = Result.create!(group: group, membership: membership1, category: category, date: Date.today, place: 3, time: nil)
      EcnProcessor.group_processor(group)
      expect(no_time.reload.ecn_points).to be_nil
    end

    it "skips results with zero time" do
      zero_time = Result.create!(group: group, membership: membership1, category: category, date: Date.today, place: 3, time: 0)
      EcnProcessor.group_processor(group)
      expect(zero_time.reload.ecn_points).to be_nil
    end

    it "does nothing when ecn_coeficient is zero" do
      group.update_column(:ecn_coeficient, 0.0)
      EcnProcessor.group_processor(group)
      expect(result1.reload.ecn_points).to be_nil
    end

    it "does nothing when group has no results" do
      empty_group = Group.create!(competition: competition, group_name: "W21", ecn_coeficient: 1.0)
      expect { EcnProcessor.group_processor(empty_group) }.not_to raise_error
    end

    it "does nothing when winner has nil time" do
      group.results.update_all(time: nil)
      expect { EcnProcessor.group_processor(group) }.not_to raise_error
      expect(result1.reload.ecn_points).to be_nil
    end
  end

  describe ".competition_processor" do
    let!(:group1) { Group.create!(competition: competition, group_name: "M21", ecn_coeficient: 1.5) }
    let!(:group2) { Group.create!(competition: competition, group_name: "W21", ecn_coeficient: 2.0) }
    let!(:result1) { Result.create!(group: group1, membership: membership1, category: category, date: Date.today, place: 1, time: 1000) }
    let!(:result2) { Result.create!(group: group2, membership: membership2, category: category, date: Date.today, place: 1, time: 800) }

    it "processes all groups in the competition" do
      EcnProcessor.competition_processor(competition)
      expect(result1.reload.ecn_points).to be_present
      expect(result2.reload.ecn_points).to be_present
    end

    it "applies correct coeficient per group" do
      EcnProcessor.competition_processor(competition)
      expect(result1.reload.ecn_points).to eq(150.0)
      expect(result2.reload.ecn_points).to eq(200.0)
    end
  end
end
