require "rails_helper"

RSpec.describe RunnersCategoryCheck, type: :job do
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category"; c.points = 0; c.validaty_period = 2 } }
  let!(:cat1)        { Category.find_or_create_by!(id: 1) { |c| c.category_name = "МСМК"; c.points = 500; c.validaty_period = 4 } }
  let!(:cat2)        { Category.find_or_create_by!(id: 2) { |c| c.category_name = "МС";   c.points = 300; c.validaty_period = 3 } }
  let!(:cat4)        { Category.find_or_create_by!(id: 4) { |c| c.category_name = "I";    c.points = 100; c.validaty_period = 2 } }
  let!(:cat5)        { Category.find_or_create_by!(id: 5) { |c| c.category_name = "II";   c.points = 50;  c.validaty_period = 2 } }
  let!(:cat6)        { Category.find_or_create_by!(id: 6) { |c| c.category_name = "III";  c.points = 25;  c.validaty_period = 2 } }
  let!(:cat7)        { Category.find_or_create_by!(id: 7) { |c| c.category_name = "Iю";   c.points = 20;  c.validaty_period = 2 } }
  let!(:cat9)        { Category.find_or_create_by!(id: 9) { |c| c.category_name = "IIIю"; c.points = 10;  c.validaty_period = 2 } }

  let!(:club)        { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Club" } }
  let!(:competition) { Competition.create!(competition_name: "Test", date: Date.new(2020, 6, 1), distance_type: "Sprint") }
  let!(:group)       { Group.create!(competition: competition, group_name: "M21") }

  let(:today) { Date.today }

  def build_runner(yob:)
    runner = Runner.create!(
      club: club, category: no_category, best_category: no_category,
      runner_name: "R", surname: "X", gender: "M", yob: yob
    )
    Membership.create!(runner: runner, club: club)
    runner
  end

  def add_result(runner, category:, date:, status: Result::CONFIRMED)
    Result.create!(
      group: group, membership: runner.memberships.first,
      category: category, date: date, status: status, skip_processing: true
    )
  end

  describe "#perform" do
    it "sets category to the latest still-valid confirmation" do
      runner = build_runner(yob: 1990)
      add_result(runner, category: cat4, date: today - 1.year)

      described_class.new.perform

      runner.reload
      expect(runner.category_id).to eq(cat4.id)
      expect(runner.category_valid).to eq((today - 1.year) + cat4.validaty_period.years)
    end

    it "demotes through the ladder when the original category has lapsed" do
      runner = build_runner(yob: 1990)
      # cat4 earned 3 years ago: cat4 expires in 2y, cat5 then expires in another 2y → valid until +1y
      earned_on = today - 3.years
      add_result(runner, category: cat4, date: earned_on)

      described_class.new.perform

      runner.reload
      expect(runner.category_id).to eq(cat5.id)
      expect(runner.category_valid).to eq(earned_on + cat4.validaty_period.years + cat5.validaty_period.years)
    end

    it "falls to NO_CATEGORY when the ladder is exhausted" do
      runner = build_runner(yob: 1990)
      # cat6 earned long ago: 6 → 7 (junior-only for adult) → NO_CATEGORY
      add_result(runner, category: cat6, date: today - 5.years)

      described_class.new.perform

      runner.reload
      expect(runner.category_id).to eq(Category::NO_CATEGORY_ID)
      expect(runner.category_valid).to eq(Date.new(2100, 1, 1))
    end

    it "picks the best across multiple earned categories" do
      runner = build_runner(yob: 1990)
      add_result(runner, category: cat5, date: today - 1.year)
      add_result(runner, category: cat4, date: today - 1.year)
      # cat2 earned 10y ago demotes through 3 → 4 → 5 → 6 before becoming valid,
      # so it does not outrank a fresh cat4.
      add_result(runner, category: cat2, date: today - 10.years)

      described_class.new.perform

      expect(runner.reload.category_id).to eq(cat4.id)
    end

    it "ignores junior categories for an aged-out runner" do
      runner = build_runner(yob: 2000) # 26+ today
      add_result(runner, category: cat7, date: today - 1.year)

      described_class.new.perform

      expect(runner.reload.category_id).to eq(Category::NO_CATEGORY_ID)
    end

    it "lets a still-junior runner use a junior category" do
      runner = build_runner(yob: today.year - 16)
      add_result(runner, category: cat9, date: today - 1.year)

      described_class.new.perform

      runner.reload
      expect(runner.category_id).to eq(cat9.id)
      expect(runner.category_valid).to be > today
    end

    it "demotes an adult cat6 holder to NO_CATEGORY rather than crossing into junior territory" do
      runner = build_runner(yob: 1990)
      # cat6 earned long enough ago that it's already expired
      add_result(runner, category: cat6, date: today - 3.years)

      described_class.new.perform

      expect(runner.reload.category_id).to eq(Category::NO_CATEGORY_ID)
    end

    it "is idempotent — does not write when stored state already matches" do
      runner = build_runner(yob: 1990)
      add_result(runner, category: cat4, date: today - 1.year)

      described_class.new.perform
      ts_first = runner.reload.updated_at

      described_class.new.perform
      expect(runner.reload.updated_at).to eq(ts_first)
    end

    it "sets NO_CATEGORY + sentinel valid date for a runner with no confirmed results" do
      runner = build_runner(yob: 1990)
      runner.update_columns(category_id: cat4.id, category_valid: today - 1)

      described_class.new.perform

      runner.reload
      expect(runner.category_id).to eq(Category::NO_CATEGORY_ID)
      expect(runner.category_valid).to eq(Date.new(2100, 1, 1))
    end
  end
end
