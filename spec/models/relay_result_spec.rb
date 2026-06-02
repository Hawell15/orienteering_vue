require "rails_helper"

RSpec.describe RelayResult do
  let!(:cat) { Category.find(4) }

  let!(:classic_competition) { Competition.create!(competition_name: "Cls", date: Date.new(2026, 5, 1), distance_type: "Ștafetă clasică") }
  let!(:sprint_competition)  { Competition.create!(competition_name: "Spr", date: Date.new(2026, 5, 1), distance_type: "Ștafetă sprint") }
  let!(:plain_competition)   { Competition.create!(competition_name: "Plain", date: Date.new(2026, 5, 1), distance_type: "Sprint") }

  let!(:classic_group) { Group.create!(competition: classic_competition, group_name: "M21S") }
  let!(:sprint_group)  { Group.create!(competition: sprint_competition,  group_name: "MX") }
  let!(:plain_group)   { Group.create!(competition: plain_competition,   group_name: "M21") }

  describe "validations" do
    it "requires exactly 3 results_id for a classic relay" do
      relay = RelayResult.new(group: classic_group, category: cat, place: 1, time: 5400, team: "MDA-1", date: Date.today, results_id: [ 1, 2 ])
      expect(relay).not_to be_valid
      expect(relay.errors[:results_id]).to be_present
    end

    it "accepts a classic relay with 3 results_id" do
      relay = RelayResult.new(group: classic_group, category: cat, place: 1, time: 5400, team: "MDA-1", date: Date.today, results_id: [ 1, 2, 3 ])
      expect(relay).to be_valid
    end

    it "requires exactly 4 results_id for a sprint relay (2W+2M)" do
      relay = RelayResult.new(group: sprint_group, category: cat, place: 1, time: 5400, team: "MDA-1", date: Date.today, results_id: [ 1, 2, 3 ])
      expect(relay).not_to be_valid
    end

    it "accepts a sprint relay with 4 results_id" do
      relay = RelayResult.new(group: sprint_group, category: cat, place: 1, time: 5400, team: "MDA-1", date: Date.today, results_id: [ 1, 2, 3, 4 ])
      expect(relay).to be_valid
    end

    it "skips the leg-count validation when the competition is not a relay" do
      relay = RelayResult.new(group: plain_group, category: cat, place: 1, time: 5400, team: "MDA-1", date: Date.today, results_id: [])
      expect(relay).to be_valid
    end
  end

  describe "legs_in_same_group validation" do
    let!(:club)       { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
    let!(:other_group) { Group.create!(competition: classic_competition, group_name: "W21S") }

    def make_leg(grp)
      runner     = Runner.create!(club: club, runner_name: "R#{SecureRandom.hex(2)}", surname: "X", gender: "M", yob: 2000)
      membership = Membership.create!(runner: runner, club: club)
      Result.create!(
        group: grp, membership: membership, category_id: Category::NO_CATEGORY_ID,
        date: classic_competition.date, time: 1800, place: 1, status: Result::UNCONFIRMED,
        skip_processing: true
      )
    end

    it "accepts a relay whose legs all belong to its group" do
      legs = 3.times.map { make_leg(classic_group) }
      relay = RelayResult.new(group: classic_group, category: cat, place: 1, time: 5400,
                              team: "OK", date: classic_competition.date, results_id: legs.map(&:id))
      expect(relay).to be_valid
    end

    it "rejects a relay whose legs include another group's results" do
      same_group_legs = 2.times.map { make_leg(classic_group) }
      foreign_leg     = make_leg(other_group)
      relay = RelayResult.new(group: classic_group, category: cat, place: 1, time: 5400,
                              team: "MIXED", date: classic_competition.date,
                              results_id: same_group_legs.map(&:id) + [ foreign_leg.id ])
      expect(relay).not_to be_valid
      expect(relay.errors[:results_id].first).to include(foreign_leg.id.to_s)
    end

    it "is a no-op when results_id is empty" do
      relay = RelayResult.new(group: plain_group, category: cat, place: 1, time: 5400,
                              team: "EMPTY", date: classic_competition.date, results_id: [])
      relay.valid?
      expect(relay.errors[:results_id]).to be_empty
    end

    it "is a no-op when group_id is blank (let belongs_to fail first)" do
      relay = RelayResult.new(group: nil, category: cat, place: 1, time: 5400,
                              team: "NOGROUP", date: classic_competition.date, results_id: [ 1 ])
      relay.valid?
      # Only the belongs_to :group error should appear; no group-mismatch noise.
      expect(relay.errors[:results_id]).to be_empty
    end
  end
end
