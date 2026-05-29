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
end
