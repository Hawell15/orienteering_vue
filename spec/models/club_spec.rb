require "rails_helper"

RSpec.describe Club, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:runners) }
    it { is_expected.to have_many(:memberships) }
  end

  describe "constants" do
    it "defines DEFAULT_CLUB_ID" do
      expect(Club::DEFAULT_CLUB_ID).to eq(1)
    end
  end

  describe "callbacks" do
    describe "before_validation :add_formatted_name" do
      it "sets formatted_name from club_name on create" do
        club = Club.create!(club_name: "Test Club")
        expect(club.formatted_name).to eq(Club.format_name("Test Club"))
      end

      it "updates formatted_name when club_name changes" do
        club = Club.create!(club_name: "Old Name")
        club.update!(club_name: "New Name")
        expect(club.formatted_name).to eq(Club.format_name("New Name"))
      end
    end

    describe "before_validation :add_formatted_alternative_names" do
      it "formats alternative_club_names" do
        club = Club.create!(club_name: "Main", alternative_club_names: [ "Alt Club" ])
        expect(club.alternative_club_names).to all(match(/\A[a-z]*\z/))
      end

      it "removes duplicates from alternative_club_names" do
        club = Club.create!(club_name: "Main", alternative_club_names: [ "Alt Club", "Alt Club" ])
        expect(club.alternative_club_names.uniq).to eq(club.alternative_club_names)
      end
    end
  end

  describe ".format_name" do
    it "returns nil for blank name" do
      expect(Club.format_name("")).to be_nil
      expect(Club.format_name(nil)).to be_nil
    end

    it "downcases and strips non-alpha characters" do
      expect(Club.format_name("Test Club 123")).to eq("testclub")
    end

    it "replaces k with c" do
      expect(Club.format_name("kk")).to eq("cc")
    end

    it "handles Romanian diacritics" do
      expect(Club.format_name("ș")).to eq("s")
      expect(Club.format_name("ț")).to eq("t")
      expect(Club.format_name("ă")).to eq("a")
      expect(Club.format_name("î")).to eq("i")
      expect(Club.format_name("â")).to eq("i")
    end
  end

  describe ".search" do
    let!(:club1) { Club.create!(club_name: "Alpha Club", territory: "North", representative: "John", email: "alpha@test.com", phone: "123") }
    let!(:club2) { Club.create!(club_name: "Beta Club", territory: "South", representative: "Jane", email: "beta@test.com", phone: "456") }

    it "finds by club_name" do
      expect(Club.search("alpha")).to include(club1)
      expect(Club.search("alpha")).not_to include(club2)
    end

    it "finds by territory" do
      expect(Club.search("north")).to include(club1)
    end

    it "finds by representative" do
      expect(Club.search("jane")).to include(club2)
    end

    it "finds by email" do
      expect(Club.search("beta@test")).to include(club2)
    end

    it "finds by phone" do
      expect(Club.search("123")).to include(club1)
    end

    it "returns empty when no match" do
      expect(Club.search("zzz")).to be_empty
    end
  end

  describe ".sorting" do
    let!(:club1) { Club.create!(club_name: "Alpha") }
    let!(:club2) { Club.create!(club_name: "Beta") }

    it "sorts by allowed column asc" do
      expect(Club.sorting("club_name", "asc")).to eq([ club1, club2 ])
    end

    it "sorts by allowed column desc" do
      expect(Club.sorting("club_name", "desc")).to eq([ club2, club1 ])
    end

    it "falls back to id for invalid column" do
      expect(Club.sorting("invalid", "asc").map(&:id)).to eq(Club.order("id asc").map(&:id))
    end

    it "falls back to asc for invalid direction" do
      expect(Club.sorting("club_name", "invalid")).to eq([ club1, club2 ])
    end
  end

  describe ".runners_count" do
    let!(:club) { Club.create!(club_name: "Test") }

    before do
      category = Category.create!(category_name: "Test")
      membership = Membership.create!(club: club, runner: Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000))
      Membership.create!(club: club, runner: Runner.create!(club: club, category: category, best_category: category, runner_name: "C", surname: "D", gender: "M", yob: 2001))
    end

    it "filters by membership count range" do
      result = Club.left_joins(:memberships).group("clubs.id").runners_count(1, 5)
      expect(result).to include(club)
    end

    it "excludes clubs outside range" do
      result = Club.left_joins(:memberships).group("clubs.id").runners_count(10, 20)
      expect(result).not_to include(club)
    end
  end

  describe ".add_club" do
    it "returns default club for blank name" do
      default_club = Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" }
      result = Club.add_club(club_name: "")
      expect(result).to eq(default_club)
    end

    it "finds existing club by formatted_name" do
      existing = Club.create!(club_name: "Test Club")
      result = Club.add_club(club_name: "Test Club")
      expect(result).to eq(existing)
    end

    it "finds club by alternative_club_names" do
      existing = Club.create!(club_name: "Main Name", alternative_club_names: [ Club.format_name("Alt Name") ])
      result = Club.add_club(club_name: "Alt Name")
      expect(result).to eq(existing)
    end

    it "creates a new club if not found" do
      Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" }
      expect {
        Club.add_club(club_name: "Brand New Club")
      }.to change(Club, :count).by(1)
    end
  end

  describe "#merge_from!" do
    let!(:main_club) { Club.create!(club_name: "Main Club") }
    let!(:other_club) { Club.create!(club_name: "Other Club") }
    let!(:category) { Category.create!(category_name: "Test") }

    it "raises error when merging into itself" do
      expect { main_club.merge_from!(main_club) }.to raise_error(ArgumentError, "Cannot merge a club into itself")
    end

    it "moves runners to the main club" do
      runner = Runner.create!(club: other_club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000)
      main_club.merge_from!(other_club)
      expect(runner.reload.club_id).to eq(main_club.id)
    end

    it "moves memberships to the main club" do
      runner = Runner.create!(club: main_club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000)
      membership = Membership.create!(club: other_club, runner: runner)
      main_club.merge_from!(other_club)
      expect(membership.reload.club_id).to eq(main_club.id)
    end

    it "merges alternative_club_names" do
      main_club.update!(alternative_club_names: [ "existing" ])
      other_club.update!(alternative_club_names: [ "other" ])
      main_club.merge_from!(other_club)
      expect(main_club.reload.alternative_club_names).to include("existing", "other")
    end

    it "destroys the other club" do
      main_club.merge_from!(other_club)
      expect { other_club.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "collapses duplicate memberships when same runner has memberships in both clubs" do
      competition = Competition.create!(competition_name: "C1", date: Date.today, distance_type: "Sprint")
      group  = Group.create!(competition: competition, group_name: "G1")
      runner = Runner.create!(club: main_club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 2000)
      main_membership  = Membership.create!(runner: runner, club: main_club)
      other_membership = Membership.create!(runner: runner, club: other_club)
      result = Result.create!(membership: other_membership, group: group, category: category, date: Date.today)

      main_club.merge_from!(other_club)

      expect(result.reload.membership_id).to eq(main_membership.id)
      expect { other_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
