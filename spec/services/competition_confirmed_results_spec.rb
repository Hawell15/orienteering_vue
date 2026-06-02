require "rails_helper"

RSpec.describe CompetitionConfirmedResults do
  let!(:no_cat) { Category.find(Category::NO_CATEGORY_ID) }
  let!(:cat3)   { Category.find(3) }
  let!(:cat4)   { Category.find(4) }
  let!(:club)   { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Olimp" } }

  let!(:competition) { Competition.create!(competition_name: "Cupa", date: Date.new(2026, 5, 1), distance_type: "Sprint") }
  let!(:group)       { Group.create!(competition: competition, group_name: "M21", clasa: "4") }
  let!(:reduction_group)     { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)         { |g| g.competition = competition; g.group_name = "REDUCTION" } }
  let!(:title_group)         { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }
  let!(:three_results_group) { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)              { |g| g.competition = competition; g.group_name = "THREE" } }

  def make_runner(name, best_category: cat4)
    Runner.create!(club: club, runner_name: name, surname: "X", gender: "M", yob: 2000, category: best_category, best_category: best_category, category_valid: Date.new(2099, 1, 1))
  end

  def make_prior(runner, category:)
    prior_comp  = Competition.create!(competition_name: "Prior-#{SecureRandom.hex(2)}", date: competition.date - 6.months, distance_type: "Sprint")
    prior_group = Group.create!(competition: prior_comp, group_name: "P")
    Result.create!(
      group: prior_group,
      membership: Membership.find_or_create_by!(runner: runner, club: club),
      category: category, date: prior_comp.date, time: 1000, place: 1,
      status: Result::CONFIRMED, skip_processing: true
    )
  end

  def make_result(runner, category:, status:, grp: group)
    Result.create!(
      group: grp,
      membership: Membership.find_or_create_by!(runner: runner, club: club),
      category: category, date: competition.date, time: 1500, place: 1,
      status: status, skip_processing: true
    )
  end

  describe "#buckets" do
    it "splits rows into capped / improved / extended" do
      capped_r   = make_runner("Capped")
      improved_r = make_runner("Improved")
      extended_r = make_runner("Extended")

      make_prior(extended_r, category: cat4)
      make_prior(improved_r, category: cat4)

      make_result(capped_r,   category: cat4, status: Result::CAPPED)
      make_result(improved_r, category: cat3, status: Result::CONFIRMED)
      make_result(extended_r, category: cat4, status: Result::CONFIRMED)

      data = described_class.new(competition).buckets

      expect(data[:capped].map(&:id)).to eq([ Result.find_by(membership: Membership.find_by(runner: capped_r)).id ])
      expect(data[:improved].map(&:id)).to eq([ Result.find_by(membership: Membership.find_by(runner: improved_r), group: group).id ])
      expect(data[:extended].map(&:id)).to eq([ Result.find_by(membership: Membership.find_by(runner: extended_r), group: group).id ])
    end
  end

  describe "#by_group" do
    it "groups rows by group_name in alphabetical order" do
      other_group = Group.create!(competition: competition, group_name: "W21", clasa: "4")
      r_a = make_result(make_runner("Aa"), category: cat4, status: Result::CONFIRMED, grp: other_group)
      r_b = make_result(make_runner("Bb"), category: cat4, status: Result::CONFIRMED, grp: group)

      pairs = described_class.new(competition).by_group
      expect(pairs.map(&:first)).to eq([ "M21", "W21" ])
      expect(pairs.first.last.map(&:id)).to eq([ r_b.id ])
      expect(pairs.last.last.map(&:id)).to eq([ r_a.id ])
    end
  end

  describe "#achievement_by_parent_id" do
    it "maps each capped parent result to its child category name" do
      capped_r = make_runner("C", best_category: cat3)
      parent   = make_result(capped_r, category: cat3, status: Result::CAPPED)
      Result.create!(
        group: title_group,
        membership: Membership.find_by(runner: capped_r),
        category: cat3, date: competition.date, time: 0, place: 0,
        status: Result::PENDING, parent_result_id: parent.id, skip_processing: true
      )

      data = described_class.new(competition)
      expect(data.achievement_by_parent_id[parent.id]).to eq("CMSRM").or eq(cat3.category_name)
    end

    it "is empty when there are no capped rows" do
      make_result(make_runner("Plain"), category: cat4, status: Result::CONFIRMED)
      expect(described_class.new(competition).achievement_by_parent_id).to be_empty
    end
  end

  describe "#empty?" do
    it "is true when nothing qualifies" do
      make_result(make_runner("Skip"), category: cat4, status: Result::UNCONFIRMED)
      expect(described_class.new(competition).empty?).to be true
    end

    it "is false when at least one row qualifies" do
      make_result(make_runner("Ok"), category: cat4, status: Result::CONFIRMED)
      expect(described_class.new(competition).empty?).to be false
    end
  end

  describe "row select projections" do
    it "exposes full_name, yob, club_name, runner_category_name, new_category_name, group_name on each row" do
      make_prior(make_runner("Ion"), category: cat4)
      runner = Runner.find_by(runner_name: "Ion")
      make_result(runner, category: cat3, status: Result::CONFIRMED)

      row = described_class.new(competition).rows.first
      expect(row.full_name).to eq("Ion X")
      expect(row.yob).to eq(2000)
      expect(row.club_name).to eq("Olimp")
      expect(row.runner_category_name).to be_present
      expect(row.new_category_name).to be_present
      expect(row.group_name).to eq("M21")
    end
  end
end
