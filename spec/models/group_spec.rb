require "rails_helper"

RSpec.describe Group, type: :model do
  let!(:competition) { Competition.create!(competition_name: "Test Comp", date: Date.today, distance_type: "Sprint") }

  describe "associations" do
    subject { Group.new(competition: competition, group_name: "M21") }

    it { is_expected.to belong_to(:competition) }
    it { is_expected.to have_many(:results).dependent(:destroy) }
  end

  describe "constants" do
    it "defines THREE_RESULTS_GROUP_ID" do
      expect(Group::THREE_RESULTS_GROUP_ID).to eq(1346)
    end

    it "defines REDUCTION_CATEGORY_GROUP_ID" do
      expect(Group::REDUCTION_CATEGORY_GROUP_ID).to eq(2)
    end

    it "defines TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID" do
      expect(Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID).to eq(2667)
    end
  end

  describe "callbacks" do
    describe "before_validation :pretify_group_name" do
      it "upcases group_name" do
        group = Group.create!(competition: competition, group_name: "m21")
        expect(group.group_name).to eq("M21")
      end

      it "removes spaces from group_name" do
        group = Group.create!(competition: competition, group_name: "m 21")
        expect(group.group_name).to eq("M21")
      end

      it "converts Cyrillic M to Latin M" do
        group = Group.create!(competition: competition, group_name: "\u041C21")
        expect(group.group_name).to eq("M21")
      end

      it "converts Cyrillic Ж to W" do
        group = Group.create!(competition: competition, group_name: "\u041621")
        expect(group.group_name).to eq("W21")
      end
    end

    describe "after_update :clear_ecn_points" do
      it "clears ecn_points on results when ecn_coeficient set to 0" do
        group = Group.create!(competition: competition, group_name: "M21", ecn_coeficient: 1.5)
        category = Category.create!(category_name: "Test")
        club = Club.create!(club_name: "Test")
        runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000)
        membership = Membership.create!(runner: runner, club: club)
        result = Result.create!(group: group, membership: membership, category: category, date: Date.today, ecn_points: 50)

        group.update!(ecn_coeficient: 0.0)
        expect(result.reload.ecn_points).to eq(0)
      end
    end
  end

  describe ".normalize_group_name" do
    it "upcases and removes spaces" do
      expect(Group.normalize_group_name("m 21")).to eq("M21")
    end

    it "converts Cyrillic М to M" do
      expect(Group.normalize_group_name("\u041C21")).to eq("M21")
    end

    it "converts Cyrillic Ж to W" do
      expect(Group.normalize_group_name("\u041621")).to eq("W21")
    end
  end

  describe ".search" do
    let!(:group1) { Group.create!(competition: competition, group_name: "M21") }
    let!(:comp2) { Competition.create!(competition_name: "Special Race", date: Date.today, distance_type: "Sprint") }
    let!(:group2) { Group.create!(competition: comp2, group_name: "W18") }

    it "finds by group_name" do
      expect(Group.search("m21")).to include(group1)
      expect(Group.search("m21")).not_to include(group2)
    end

    it "finds by competition_name" do
      expect(Group.search("special")).to include(group2)
    end

    it "returns empty when no match" do
      expect(Group.search("zzz")).to be_empty
    end
  end

  describe ".sorting" do
    let!(:group1) { Group.create!(competition: competition, group_name: "A21") }
    let!(:group2) { Group.create!(competition: competition, group_name: "B21") }

    it "sorts by allowed column asc" do
      expect(Group.sorting("group_name", "asc")).to eq([ group1, group2 ])
    end

    it "sorts by allowed column desc" do
      expect(Group.sorting("group_name", "desc")).to eq([ group2, group1 ])
    end

    it "falls back to id for invalid column" do
      expect(Group.sorting("invalid", "asc")).to eq(Group.order("id asc"))
    end

    it "falls back to asc for invalid direction" do
      expect(Group.sorting("group_name", "invalid")).to eq([ group1, group2 ])
    end
  end

  describe ".competition scope" do
    let!(:group1) { Group.create!(competition: competition, group_name: "M21") }
    let!(:comp2) { Competition.create!(competition_name: "Other", date: Date.today, distance_type: "Sprint") }
    let!(:group2) { Group.create!(competition: comp2, group_name: "W21") }

    it "returns all for 'all'" do
      expect(Group.competition("all")).to include(group1, group2)
    end

    it "filters by competition_id" do
      expect(Group.competition(competition.id)).to include(group1)
      expect(Group.competition(competition.id)).not_to include(group2)
    end
  end

  describe ".clasa" do
    let!(:group1) { Group.create!(competition: competition, group_name: "M21", clasa: "A") }
    let!(:group2) { Group.create!(competition: competition, group_name: "W21", clasa: "B") }

    it "returns all for 'all'" do
      expect(Group.clasa("all")).to include(group1, group2)
    end

    it "filters by specific clasa" do
      expect(Group.clasa("A")).to include(group1)
      expect(Group.clasa("A")).not_to include(group2)
    end
  end

  describe ".results_count" do
    let!(:group) { Group.create!(competition: competition, group_name: "M21") }
    let!(:category) { Category.create!(category_name: "Test") }
    let!(:club) { Club.create!(club_name: "Test") }

    before do
      runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000)
      membership = Membership.create!(runner: runner, club: club)
      2.times { Result.create!(group: group, membership: membership, category: category, date: Date.today) }
    end

    it "filters by results count range" do
      result = Group.left_joins(:results).group("groups.id").results_count(1, 5)
      expect(result).to include(group)
    end

    it "excludes groups outside range" do
      result = Group.left_joins(:results).group("groups.id").results_count(10, 20)
      expect(result).not_to include(group)
    end
  end

  describe ".date" do
    let!(:old_comp) { Competition.create!(competition_name: "Old", date: Date.new(2020, 1, 1), distance_type: "Sprint") }
    let!(:new_comp) { Competition.create!(competition_name: "New", date: Date.new(2025, 6, 1), distance_type: "Sprint") }
    let!(:old_group) { Group.create!(competition: old_comp, group_name: "M21") }
    let!(:new_group) { Group.create!(competition: new_comp, group_name: "W21") }

    it "filters groups by competition date range" do
      result = Group.date(Date.new(2024, 1, 1), Date.new(2026, 1, 1))
      expect(result).to include(new_group)
      expect(result).not_to include(old_group)
    end
  end

  describe ".add_group" do
    it "finds group by group_id" do
      group = Group.create!(competition: competition, group_name: "M21")
      result = Group.add_group("group_id" => group.id)
      expect(result).to eq(group)
    end

    it "finds or creates group by params" do
      expect {
        Group.add_group(competition_id: competition.id, group_name: "W18")
      }.to change(Group, :count).by(1)
    end

    it "finds existing group by params" do
      group = Group.create!(competition: competition, group_name: "M21")
      result = Group.add_group(competition_id: competition.id, group_name: "M21")
      expect(result).to eq(group)
    end
  end
end
