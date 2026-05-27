require "rails_helper"

RSpec.describe ResultCategorizer do
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category"; c.points = 0; c.validaty_period = 2 } }
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
end
