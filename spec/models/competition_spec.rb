require "rails_helper"

RSpec.describe Competition, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:groups).dependent(:destroy) }
  end

  describe "constants" do
    it "defines DISTANCE_TYPES" do
      expect(Competition::DISTANCE_TYPES).to include("Sprint", "Medie", "Lungă")
    end
  end

  describe "default values" do
    it "defaults country to Moldova" do
      comp = Competition.create!(competition_name: "Test", date: Date.today, distance_type: "Sprint")
      expect(comp.country).to eq("Moldova")
    end

    it "defaults ecn to false" do
      comp = Competition.create!(competition_name: "Test", date: Date.today, distance_type: "Sprint")
      expect(comp.ecn).to be false
    end
  end

  describe "callbacks" do
    describe "before_save :add_checksum" do
      it "generates checksum on create" do
        comp = Competition.create!(competition_name: "Test", date: Date.new(2025, 1, 1), distance_type: "Sprint")
        expect(comp.checksum).to be_present
      end

      it "updates checksum when attributes change" do
        comp = Competition.create!(competition_name: "Test", date: Date.new(2025, 1, 1), distance_type: "Sprint")
        old_checksum = comp.checksum
        comp.update!(competition_name: "Changed")
        expect(comp.checksum).not_to eq(old_checksum)
      end
    end

    describe "after_update :clear_ecn_data" do
      it "clears ecn_coeficient on groups when ecn toggled to false" do
        comp = Competition.create!(competition_name: "Test", date: Date.today, distance_type: "Sprint", ecn: true)
        group = Group.create!(competition: comp, group_name: "M21", ecn_coeficient: 1.5)
        comp.update!(ecn: false)
        expect(group.reload.ecn_coeficient).to eq(0.0)
      end

      it "does not clear ecn_coeficient when ecn stays true" do
        comp = Competition.create!(competition_name: "Test", date: Date.today, distance_type: "Sprint", ecn: true)
        group = Group.create!(competition: comp, group_name: "M21", ecn_coeficient: 1.5)
        comp.update!(competition_name: "Updated")
        expect(group.reload.ecn_coeficient).to eq(1.5)
      end
    end
  end

  describe ".get_checksum" do
    it "returns consistent checksum for same inputs" do
      checksum1 = Competition.get_checksum("Test", Date.new(2025, 1, 1), "Sprint", nil)
      checksum2 = Competition.get_checksum("Test", Date.new(2025, 1, 1), "Sprint", nil)
      expect(checksum1).to eq(checksum2)
    end

    it "returns different checksums for different inputs" do
      checksum1 = Competition.get_checksum("Test1", Date.new(2025, 1, 1), "Sprint", nil)
      checksum2 = Competition.get_checksum("Test2", Date.new(2025, 1, 1), "Sprint", nil)
      expect(checksum1).not_to eq(checksum2)
    end
  end

  describe ".search" do
    let!(:comp1) { Competition.create!(competition_name: "Cupa Moldovei", date: Date.today, distance_type: "Sprint", location: "Chisinau", country: "Moldova") }
    let!(:comp2) { Competition.create!(competition_name: "World Cup", date: Date.today, distance_type: "Medie", location: "Paris", country: "France") }

    it "finds by competition_name" do
      expect(Competition.search("cupa")).to include(comp1)
      expect(Competition.search("cupa")).not_to include(comp2)
    end

    it "finds by location" do
      expect(Competition.search("paris")).to include(comp2)
    end

    it "finds by country" do
      expect(Competition.search("france")).to include(comp2)
    end

    it "returns empty when no match" do
      expect(Competition.search("zzz")).to be_empty
    end
  end

  describe ".sorting" do
    let!(:comp1) { Competition.create!(competition_name: "Alpha", date: Date.new(2025, 1, 1), distance_type: "Sprint") }
    let!(:comp2) { Competition.create!(competition_name: "Beta", date: Date.new(2025, 6, 1), distance_type: "Medie") }

    it "sorts by allowed column asc" do
      expect(Competition.sorting("competition_name", "asc")).to eq([ comp1, comp2 ])
    end

    it "sorts by allowed column desc" do
      expect(Competition.sorting("competition_name", "desc")).to eq([ comp2, comp1 ])
    end

    it "sorts by date" do
      expect(Competition.sorting("date", "asc")).to eq([ comp1, comp2 ])
    end

    it "falls back to id for invalid column" do
      expect(Competition.sorting("invalid", "asc")).to eq(Competition.order("id asc"))
    end

    it "falls back to asc for invalid direction" do
      expect(Competition.sorting("competition_name", "invalid")).to eq([ comp1, comp2 ])
    end
  end

  describe ".country" do
    let!(:moldovan) { Competition.create!(competition_name: "Local", date: Date.today, distance_type: "Sprint", country: "Moldova") }
    let!(:foreign) { Competition.create!(competition_name: "Foreign", date: Date.today, distance_type: "Sprint", country: "Romania") }

    it "returns international competitions" do
      expect(Competition.country("international")).to include(foreign)
      expect(Competition.country("international")).not_to include(moldovan)
    end

    it "returns all for 'all'" do
      expect(Competition.country("all")).to include(moldovan, foreign)
    end

    it "filters by specific country" do
      expect(Competition.country("Moldova")).to include(moldovan)
      expect(Competition.country("Moldova")).not_to include(foreign)
    end
  end

  describe ".distance_type" do
    let!(:sprint) { Competition.create!(competition_name: "A", date: Date.today, distance_type: "Sprint") }
    let!(:medie) { Competition.create!(competition_name: "B", date: Date.today, distance_type: "Medie") }

    it "returns all for 'all'" do
      expect(Competition.distance_type("all")).to include(sprint, medie)
    end

    it "filters by specific distance_type" do
      expect(Competition.distance_type("Sprint")).to include(sprint)
      expect(Competition.distance_type("Sprint")).not_to include(medie)
    end
  end

  describe ".wre" do
    let!(:wre_comp) { Competition.create!(competition_name: "WRE", date: Date.today, distance_type: "Sprint", wre_id: 123) }
    let!(:non_wre) { Competition.create!(competition_name: "Local", date: Date.today, distance_type: "Sprint", wre_id: nil) }

    it "returns only competitions with wre_id" do
      expect(Competition.wre).to include(wre_comp)
      expect(Competition.wre).not_to include(non_wre)
    end
  end

  describe ".ecn" do
    let!(:ecn_comp) { Competition.create!(competition_name: "ECN", date: Date.today, distance_type: "Sprint", ecn: true) }
    let!(:non_ecn) { Competition.create!(competition_name: "Local", date: Date.today, distance_type: "Sprint", ecn: false) }

    it "returns only ecn competitions" do
      expect(Competition.ecn).to include(ecn_comp)
      expect(Competition.ecn).not_to include(non_ecn)
    end
  end

  describe ".date" do
    let!(:old_comp) { Competition.create!(competition_name: "Old", date: Date.new(2020, 1, 1), distance_type: "Sprint") }
    let!(:new_comp) { Competition.create!(competition_name: "New", date: Date.new(2025, 6, 1), distance_type: "Sprint") }

    it "filters by date range" do
      expect(Competition.date(Date.new(2024, 1, 1), Date.new(2026, 1, 1))).to include(new_comp)
      expect(Competition.date(Date.new(2024, 1, 1), Date.new(2026, 1, 1))).not_to include(old_comp)
    end
  end

  describe ".add_competition" do
    it "creates a new competition" do
      expect {
        Competition.add_competition(competition_name: "New Comp", date: Date.new(2025, 3, 1), distance_type: "Sprint")
      }.to change(Competition, :count).by(1)
    end

    it "finds existing competition by wre_id" do
      existing = Competition.create!(competition_name: "Existing", date: Date.today, distance_type: "Sprint", wre_id: 999)
      result = Competition.add_competition(competition_name: "Different Name", date: Date.today, distance_type: "Sprint", wre_id: 999)
      expect(result).to eq(existing)
    end

    it "finds existing competition by checksum" do
      existing = Competition.create!(competition_name: "Test", date: Date.new(2025, 1, 1), distance_type: "Sprint")
      result = Competition.add_competition(competition_name: "Test", date: Date.new(2025, 1, 1), distance_type: "Sprint")
      expect(result).to eq(existing)
    end

    it "finds existing competition by competition_id" do
      existing = Competition.create!(competition_name: "Existing", date: Date.today, distance_type: "Sprint")
      result = Competition.add_competition(competition_name: "Other", date: Date.today, distance_type: "Medie", competition_id: existing.id)
      expect(result).to eq(existing)
    end
  end
end
