require "rails_helper"

RSpec.describe Runner, type: :model do
  let!(:category) { Category.create!(category_name: "Test", points: 100, validaty_period: 2) }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category" } }
  let!(:club) { Club.create!(club_name: "Test Club") }

  describe "associations" do
    it { is_expected.to belong_to(:club) }
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:best_category) }
    it { is_expected.to have_many(:memberships).dependent(:destroy) }
    it { is_expected.to have_many(:results).through(:memberships) }
  end

  describe "callbacks" do
    describe "before_save :add_checksum" do
      it "generates checksum on create" do
        runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000)
        expect(runner.checksum).to be_present
      end

      it "updates checksum when attributes change" do
        runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000)
        old_checksum = runner.checksum
        runner.update!(runner_name: "Jane")
        expect(runner.checksum).not_to eq(old_checksum)
      end
    end
  end

  describe ".get_checksum" do
    it "returns consistent checksum for same inputs" do
      c1 = Runner.get_checksum("John", "Doe", 2000, "M")
      c2 = Runner.get_checksum("John", "Doe", 2000, "M")
      expect(c1).to eq(c2)
    end

    it "returns different checksums for different inputs" do
      c1 = Runner.get_checksum("John", "Doe", 2000, "M")
      c2 = Runner.get_checksum("Jane", "Doe", 2000, "W")
      expect(c1).not_to eq(c2)
    end
  end

  describe ".search" do
    let!(:runner1) { Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000) }
    let!(:club2) { Club.create!(club_name: "Alpha Club") }
    let!(:runner2) { Runner.create!(club: club2, category: category, best_category: category, runner_name: "Jane", surname: "Smith", gender: "W", yob: 2001) }

    it "returns all for blank search" do
      result = Runner.search("")
      expect(result).to include(runner1, runner2)
    end
  end

  describe ".sorting" do
    let!(:runner1) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "A", gender: "M", yob: 2000) }
    let!(:runner2) { Runner.create!(club: club, category: category, best_category: category, runner_name: "B", surname: "B", gender: "M", yob: 2001) }

    it "sorts by allowed column" do
      expect(Runner.sorting("yob", "asc")).to eq([ runner1, runner2 ])
    end

    it "sorts desc" do
      expect(Runner.sorting("yob", "desc")).to eq([ runner2, runner1 ])
    end

    it "falls back to id for invalid column" do
      expect(Runner.sorting("invalid", "asc")).to eq(Runner.order("id asc"))
    end

    it "defaults direction to desc" do
      expect(Runner.sorting("yob", "invalid")).to eq([ runner2, runner1 ])
    end
  end

  describe ".club scope" do
    let!(:runner1) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "A", gender: "M", yob: 2000) }
    let!(:club2) { Club.create!(club_name: "Other") }
    let!(:runner2) { Runner.create!(club: club2, category: category, best_category: category, runner_name: "B", surname: "B", gender: "M", yob: 2001) }

    it "returns all for 'all'" do
      expect(Runner.club("all")).to include(runner1, runner2)
    end

    it "filters by club_id" do
      expect(Runner.club(club.id)).to include(runner1)
      expect(Runner.club(club.id)).not_to include(runner2)
    end
  end

  describe ".category scope" do
    let!(:cat2) { Category.create!(category_name: "Other") }
    let!(:runner1) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "A", gender: "M", yob: 2000) }
    let!(:runner2) { Runner.create!(club: club, category: cat2, best_category: cat2, runner_name: "B", surname: "B", gender: "M", yob: 2001) }

    it "returns all for 'all'" do
      expect(Runner.category("all")).to include(runner1, runner2)
    end

    it "filters by category_id" do
      expect(Runner.category(category.id)).to include(runner1)
      expect(Runner.category(category.id)).not_to include(runner2)
    end
  end

  describe ".best_category scope" do
    let!(:cat2) { Category.create!(category_name: "Other") }
    let!(:runner1) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "A", gender: "M", yob: 2000) }
    let!(:runner2) { Runner.create!(club: club, category: category, best_category: cat2, runner_name: "B", surname: "B", gender: "M", yob: 2001) }

    it "returns all for 'all'" do
      expect(Runner.best_category("all")).to include(runner1, runner2)
    end

    it "filters by best_category_id" do
      expect(Runner.best_category(category.id)).to include(runner1)
      expect(Runner.best_category(category.id)).not_to include(runner2)
    end
  end

  describe ".gender scope" do
    let!(:male) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "A", gender: "M", yob: 2000) }
    let!(:female) { Runner.create!(club: club, category: category, best_category: category, runner_name: "B", surname: "B", gender: "W", yob: 2001) }

    it "returns all for 'all'" do
      expect(Runner.gender("all")).to include(male, female)
    end

    it "filters by gender" do
      expect(Runner.gender("M")).to include(male)
      expect(Runner.gender("M")).not_to include(female)
    end
  end

  describe ".wre" do
    let!(:wre_runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "A", gender: "M", yob: 2000, wre_id: 123) }
    let!(:non_wre) { Runner.create!(club: club, category: category, best_category: category, runner_name: "B", surname: "B", gender: "M", yob: 2001, wre_id: nil) }

    it "returns only runners with wre_id" do
      expect(Runner.wre).to include(wre_runner)
      expect(Runner.wre).not_to include(non_wre)
    end
  end

  describe ".yob" do
    let!(:young) { Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "A", gender: "M", yob: 2005) }
    let!(:old) { Runner.create!(club: club, category: category, best_category: category, runner_name: "B", surname: "B", gender: "M", yob: 1990) }

    it "filters by yob range" do
      expect(Runner.yob(2000, 2010)).to include(young)
      expect(Runner.yob(2000, 2010)).not_to include(old)
    end
  end

  describe "#junior_runner?" do
    it "returns true for runners under 18" do
      runner = Runner.new(yob: Time.now.year - 15)
      expect(runner.junior_runner?).to be true
    end

    it "returns false for runners 18 or older" do
      runner = Runner.new(yob: Time.now.year - 20)
      expect(runner.junior_runner?).to be false
    end
  end

  describe ".matching_runner" do
    let!(:runner) { Runner.create!(club: club, category: category, best_category: category, runner_name: "John", surname: "Doe", gender: "M", yob: 2000, wre_id: 555) }

    it "matches by wre_id" do
      result = Runner.matching_runner(wre_id: 555, id: -1, "runner_name" => "X", "surname" => "Y", "yob" => "0", "gender" => "W")
      expect(result).to include(runner)
    end

    it "matches by id" do
      result = Runner.matching_runner(wre_id: -1, id: runner.id, "runner_name" => "X", "surname" => "Y", "yob" => "0", "gender" => "W")
      expect(result).to include(runner)
    end

    it "matches by checksum" do
      result = Runner.matching_runner(wre_id: -1, id: -1, "runner_name" => "John", "surname" => "Doe", "yob" => "2000", "gender" => "M")
      expect(result).to include(runner)
    end
  end

  describe ".update_yob" do
    it "updates yob when runner yob is zero" do
      runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 0)
      Runner.send(:update_yob, runner, 2000)
      expect(runner.reload.yob).to eq(2000)
    end

    it "does not update yob when runner already has one" do
      runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 1999)
      Runner.send(:update_yob, runner, 2000)
      expect(runner.reload.yob).to eq(1999)
    end

    it "does not update when new yob is zero" do
      runner = Runner.create!(club: club, category: category, best_category: category, runner_name: "A", surname: "B", gender: "M", yob: 0)
      Runner.send(:update_yob, runner, 0)
      expect(runner.reload.yob).to eq(0)
    end
  end
end
