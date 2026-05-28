require "rails_helper"

RSpec.describe ResultCategorizer do
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category"; c.points = 0; c.validaty_period = 2 } }
  let!(:cat1)        { Category.find_or_create_by!(id: 1) { |c| c.category_name = "МСМК";  c.points = 500; c.validaty_period = 4 } }
  let!(:cat2)        { Category.find_or_create_by!(id: 2) { |c| c.category_name = "Cat II"; c.points = 200; c.validaty_period = 4 } }
  let!(:cat4)        { Category.find_or_create_by!(id: 4) { |c| c.category_name = "Cat IV"; c.points = 100; c.validaty_period = 2 } }
  let!(:cat5)        { Category.find_or_create_by!(id: 5) { |c| c.category_name = "Cat V"; c.points = 50;  c.validaty_period = 2 } }

  let!(:club_a) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Club A" } }
  let!(:club_b) { Club.create!(club_name: "Club B") }

  let!(:competition)         { Competition.create!(competition_name: "Test", date: Date.new(2025, 6, 1), distance_type: "Sprint") }
  let!(:group)               { Group.create!(competition: competition, group_name: "M21") }
  let!(:title_group)         { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }
  let!(:three_results_group) { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID) { |g| g.competition = competition; g.group_name = "THREE" } }

  let!(:runner_a) { Runner.create!(club: club_a, category: no_category, best_category: no_category, runner_name: "John",   surname: "A", gender: "M", yob: 2000) }
  let!(:runner_b) { Runner.create!(club: club_a, category: no_category, best_category: no_category, runner_name: "Roman", surname: "B", gender: "M", yob: 2000) }

  let!(:membership_a1) { Membership.create!(runner: runner_a, club: club_a) }
  let!(:membership_a2) { Membership.create!(runner: runner_a, club: club_b) }
  let!(:membership_b)  { Membership.create!(runner: runner_b, club: club_a) }

  describe "skip_processing" do
    it "bypasses the cap on create" do
      result = Result.create!(
        group: group, membership: membership_a1, category: cat2,
        date: Date.new(2025, 6, 1), skip_processing: true
      )

      expect(result.category_id).to eq(cat2.id)
      expect(result.status).to eq(Result::UNCONFIRMED)
      expect(result.child_results).to be_empty
    end
  end

  describe "parent_result_id guard" do
    it "does not re-cap or destroy children of a pending child row" do
      parent = Result.create!(
        group: group, membership: membership_a1, category: cat2,
        date: Date.new(2025, 6, 1)
      )
      pending = parent.child_results.find_by(group_id: title_group.id)

      expect(pending).to be_present
      expect(pending.category_id).to eq(cat2.id)
      expect(pending.status).to eq(Result::PENDING)
      expect(pending.parent_result_id).to eq(parent.id)
    end
  end

  describe "date change as a reprocess trigger" do
    it "fires the cap when date changes" do
      result = Result.create!(
        group: group, membership: membership_a1, category: cat2,
        date: Date.new(2025, 6, 1), skip_processing: true
      )
      expect(result.child_results.find_by(group_id: title_group.id)).to be_nil

      result.skip_processing = false
      result.update!(date: Date.new(2025, 7, 1))

      pending = result.reload.child_results.find_by(group_id: title_group.id)
      expect(pending).to be_present
      expect(pending.category_id).to eq(cat2.id)
    end
  end

  describe "membership swap" do
    it "does not reprocess when the swap stays with the same runner" do
      result = Result.create!(
        group: group, membership: membership_a1, category: cat2,
        date: Date.new(2025, 6, 1), skip_processing: true
      )

      result.skip_processing = false
      result.update!(membership: membership_a2)

      expect(result.reload.child_results.find_by(group_id: title_group.id)).to be_nil
      expect(result.reload.category_id).to eq(cat2.id)
    end

    it "reprocesses when the swap moves the result to a different runner" do
      result = Result.create!(
        group: group, membership: membership_a1, category: cat2,
        date: Date.new(2025, 6, 1), skip_processing: true
      )
      expect(result.child_results.find_by(group_id: title_group.id)).to be_nil

      result.skip_processing = false
      result.update!(membership: membership_b)

      pending = result.reload.child_results.find_by(group_id: title_group.id)
      expect(pending).to be_present
      expect(pending.category_id).to eq(cat2.id)
    end
  end

  describe "runner state refresh in after_save" do
    it "updates runner.category_id and category_valid from the saved result" do
      result = Result.create!(
        group: group, membership: membership_a1, category: cat4,
        date: Date.new(2025, 6, 1)
      )

      runner_a.reload
      expect(runner_a.category_id).to eq(cat4.id)
      expect(runner_a.category_valid).to eq(result.date + cat4.validaty_period.years)
    end

    it "monotonically improves runner.best_category_id" do
      Result.create!(group: group, membership: membership_a1, category: cat5, date: Date.new(2025, 5, 1))
      expect(runner_a.reload.best_category_id).to eq(cat5.id)

      Result.create!(group: group, membership: membership_a1, category: cat4, date: Date.new(2025, 6, 1))
      expect(runner_a.reload.best_category_id).to eq(cat4.id)
    end

    it "reads fresh runner.best_category_id when the runner is updated externally between saves" do
      # Normal-flow create populates and caches @result.runner via the
      # update_runner_category call in after_save.
      existing = Result.create!(
        group: group, membership: membership_a1, category: no_category,
        date: Date.new(2025, 6, 1), status: Result::UNCONFIRMED
      )

      # External bump via a different in-memory Runner instance — the
      # cached @result.runner would now disagree with the DB.
      runner_a.update!(best_category_id: cat1.id)

      # cat2 is a title category. Without the before_save cache reset,
      # apply_cap would read stale best=10 and create a PENDING child
      # (2 < 4 && 2 < 10). With the reset it reads fresh best=1 (2 < 1
      # false) and creates none.
      expect {
        existing.update!(category_id: cat2.id)
      }.not_to change(Result, :count)

      expect(existing.reload.status).to eq(Result::CONFIRMED)
      expect(existing.reload.category_id).to eq(cat2.id)
    end
  end
end
