require "rails_helper"

RSpec.describe Membership, type: :model do
  let!(:category) { Category.create!(category_name: "Test") }
  let!(:club) { Club.create!(club_name: "Test Club") }
  let!(:runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000) }

  describe "associations" do
    it { is_expected.to belong_to(:runner) }
    it { is_expected.to belong_to(:club) }
    it { is_expected.to have_many(:results) }
  end

  describe ".search" do
    let!(:club2) { Club.create!(club_name: "Alpha Club") }
    let!(:runner2) { Runner.create!(club: club2, category: category, best_category: category, runner_name: "Jane", surname: "Smith", gender: "W", yob: 2001) }
    let!(:membership1) { Membership.create!(runner: runner, club: club) }
    let!(:membership2) { Membership.create!(runner: runner2, club: club2) }

    it "finds by runner name" do
      expect(Membership.search("john")).to include(membership1)
      expect(Membership.search("john")).not_to include(membership2)
    end

    it "finds by runner surname first" do
      expect(Membership.search("doe john")).to include(membership1)
    end

    it "finds by club_name" do
      expect(Membership.search("alpha")).to include(membership2)
    end

    it "returns empty when no match" do
      expect(Membership.search("zzz")).to be_empty
    end
  end

  describe ".sorting" do
    let!(:membership1) { Membership.create!(runner: runner, club: club) }

    it "sorts by allowed column asc" do
      expect(Membership.sorting("id", "asc")).to eq(Membership.order("id asc"))
    end

    it "falls back to id for invalid column" do
      expect(Membership.sorting("invalid", "asc")).to eq(Membership.order("id asc"))
    end

    it "falls back to asc for invalid direction" do
      expect(Membership.sorting("id", "invalid")).to eq(Membership.order("id asc"))
    end
  end

  describe ".club scope" do
    let!(:club2) { Club.create!(club_name: "Other Club") }
    let!(:membership1) { Membership.create!(runner: runner, club: club) }
    let!(:membership2) { Membership.create!(runner: runner, club: club2) }

    it "returns all for 'all'" do
      expect(Membership.club("all")).to include(membership1, membership2)
    end

    it "filters by club_id" do
      expect(Membership.club(club.id)).to include(membership1)
      expect(Membership.club(club.id)).not_to include(membership2)
    end
  end

  describe ".runner scope" do
    let!(:runner2) { Runner.create!(club: club, category: category, best_category: category, runner_name: "Jane", surname: "Smith", gender: "W", yob: 2001) }
    let!(:membership1) { Membership.create!(runner: runner, club: club) }
    let!(:membership2) { Membership.create!(runner: runner2, club: club) }

    it "returns all for 'all'" do
      expect(Membership.runner("all")).to include(membership1, membership2)
    end

    it "filters by runner_id" do
      expect(Membership.runner(runner.id)).to include(membership1)
      expect(Membership.runner(runner.id)).not_to include(membership2)
    end
  end

  describe ".results_count" do
    let!(:membership) { Membership.create!(runner: runner, club: club) }
    let!(:competition) { Competition.create!(competition_name: "Test", date: Date.today, distance_type: "Sprint") }
    let!(:group) { Group.create!(competition: competition, group_name: "M21") }

    before do
      3.times { Result.create!(membership: membership, group: group, category: category, date: Date.today) }
    end

    it "filters by results count range" do
      result = Membership.left_joins(:results).group("memberships.id").results_count(2, 5)
      expect(result).to include(membership)
    end

    it "excludes memberships outside range" do
      result = Membership.left_joins(:results).group("memberships.id").results_count(10, 20)
      expect(result).not_to include(membership)
    end
  end

  describe ".add_membership" do
    it "creates a new membership" do
      expect {
        Membership.add_membership(runner_id: runner.id, club_id: club.id)
      }.to change(Membership, :count).by(1)
    end

    it "finds existing membership" do
      existing = Membership.create!(runner: runner, club: club)
      result = Membership.add_membership(runner_id: runner.id, club_id: club.id)
      expect(result).to eq(existing)
    end
  end
end
