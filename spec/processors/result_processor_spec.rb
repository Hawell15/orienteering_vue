require "rails_helper"

RSpec.describe ResultProcessor do
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category"; c.points = 0; c.validaty_period = 2 } }
  let!(:cat1) { Category.find_or_create_by!(id: 1) { |c| c.category_name = "Master"; c.points = 500; c.validaty_period = 4 } }
  let!(:cat2) { Category.find_or_create_by!(id: 2) { |c| c.category_name = "Cat I"; c.points = 300; c.validaty_period = 4 } }
  let!(:cat3) { Category.find_or_create_by!(id: 3) { |c| c.category_name = "Cat II"; c.points = 200; c.validaty_period = 4 } }
  let!(:cat4) { Category.find_or_create_by!(id: 4) { |c| c.category_name = "Cat III"; c.points = 100; c.validaty_period = 2 } }
  let!(:cat5) { Category.find_or_create_by!(id: 5) { |c| c.category_name = "Cat IV"; c.points = 50; c.validaty_period = 2 } }
  let!(:cat9) { Category.find_or_create_by!(id: 9) { |c| c.category_name = "Junior III"; c.points = 10; c.validaty_period = 2 } }

  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Test Club" } }
  let!(:competition) { Competition.create!(competition_name: "Test", date: Date.new(2025, 6, 1), distance_type: "Sprint") }
  let!(:group) { Group.create!(competition: competition, group_name: "M21") }
  let!(:reduction_group) { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID) { |g| g.competition = competition; g.group_name = "REDUCTION" } }
  let!(:three_results_group) { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID) { |g| g.competition = competition; g.group_name = "THREE" } }
  let!(:title_group) { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }

  let!(:runner) do
    Runner.create!(
      club: club, category: no_category, best_category: no_category,
      runner_name: "John", surname: "Doe", gender: "M", yob: 2000
    )
  end
  let!(:membership) { Membership.create!(runner: runner, club: club) }

  def build_params(overrides = {})
    {
      runner_id: runner.id,
      membership: club.club_name,
      group_id: group.id,
      category_id: cat5.id,
      date: Date.new(2025, 6, 1),
      place: 1,
      time: 3600,
      status: nil
    }.merge(overrides)
  end

  describe "#initialize" do
    it "sets params, result, and runner" do
      processor = ResultProcessor.new(build_params)
      expect(processor.params).to be_a(HashWithIndifferentAccess)
      expect(processor.runner).to eq(runner)
    end

    it "raises when runner_id is invalid" do
      expect {
        ResultProcessor.new(build_params(runner_id: -1))
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "coerces string category_id and group_id to integers" do
      processor = ResultProcessor.new(build_params(category_id: "10", group_id: "2"))
      expect(processor.params["category_id"]).to eq(10)
      expect(processor.params["group_id"]).to eq(2)
    end
  end

  describe "#add_result" do
    it "creates a new result" do
      processor = ResultProcessor.new(build_params)
      expect {
        processor.add_result
      }.to change(Result, :count).by(1)
    end

    it "sets default status to unconfirmed when category is NO_CATEGORY" do
      processor = ResultProcessor.new(build_params(category_id: no_category.id))
      processor.add_result
      expect(processor.result.status).to eq(Result::UNCONFIRMED)
    end

    it "creates a membership via club name" do
      processor = ResultProcessor.new(build_params)
      processor.add_result
      expect(processor.result.membership.runner_id).to eq(runner.id)
      expect(processor.result.membership.club_id).to eq(club.id)
    end

    it "assigns the correct group_id" do
      processor = ResultProcessor.new(build_params)
      processor.add_result
      expect(processor.result.group_id).to eq(group.id)
    end

    context "when result already exists for the same membership and group" do
      let!(:existing) { Result.create!(group: group, membership: membership, category: no_category, date: Date.new(2025, 6, 1), status: Result::UNCONFIRMED) }

      it "updates the existing result via update_result" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat5.id }, existing)
        expect {
          processor.update_result
        }.not_to change(Result, :count)
        expect(existing.reload.category_id).to eq(cat5.id)
      end

      it "does not update if category_id is unchanged" do
        existing.update!(category_id: cat5.id)
        processor = ResultProcessor.new(build_params(category_id: cat5.id))
        processor.add_result
        expect(existing.reload.category_id).to eq(cat5.id)
      end

      it "applies a status-only change when category is unchanged" do
        existing.update!(category_id: cat5.id, status: Result::UNCONFIRMED)
        processor = ResultProcessor.new(build_params(category_id: cat5.id, status: Result::CONFIRMED))
        processor.add_result
        expect(existing.reload.status).to eq(Result::CONFIRMED)
      end

      it "is a no-op when both category and status are unchanged" do
        existing.update!(category_id: cat5.id, status: Result::CONFIRMED)
        processor = ResultProcessor.new(build_params(category_id: cat5.id, status: Result::CONFIRMED))
        expect_any_instance_of(Result).not_to receive(:update!)
        processor.add_result
      end

      it "is a no-op when params has neither category_id nor status (sparse update)" do
        existing.update!(category_id: cat5.id, status: Result::CONFIRMED)
        processor = ResultProcessor.new({ runner_id: runner.id }, existing)
        expect_any_instance_of(Result).not_to receive(:update!)
        processor.update_result
      end

      it "update_result with a status-only param flips status without touching the category" do
        existing.update!(category_id: cat5.id, status: Result::UNCONFIRMED)
        processor = ResultProcessor.new({ runner_id: runner.id, status: Result::CONFIRMED }, existing)
        processor.update_result
        existing.reload
        expect(existing.status).to eq(Result::CONFIRMED)
        expect(existing.category_id).to eq(cat5.id)
      end

      it "update_result does not call add_membership_id" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat5.id }, existing)
        expect(processor).not_to receive(:add_membership_id)
        processor.update_result
        expect(existing.reload.category_id).to eq(cat5.id)
      end
    end

    context "with better_category? logic" do
      it "sets status to confirmed when assigning a better category (reduction group)" do
        processor = ResultProcessor.new(build_params(group_id: reduction_group.id, category_id: cat4.id))
        processor.add_result
        expect(processor.result.status).to eq(Result::CONFIRMED)
      end

      it "sets status to confirmed when runner has no prior category on date" do
        processor = ResultProcessor.new(build_params(category_id: cat5.id))
        processor.add_result
        expect(processor.result.status).to eq(Result::CONFIRMED)
      end

      it "does not confirm when category is NO_CATEGORY" do
        processor = ResultProcessor.new(build_params(category_id: no_category.id))
        processor.add_result
        expect(processor.result.status).to eq(Result::UNCONFIRMED)
      end
    end

    context "with create_pending_result (title categories)" do
      let!(:existing) { Result.create!(group: group, membership: membership, category: no_category, date: Date.new(2025, 6, 1), status: Result::UNCONFIRMED) }

      before do
        runner.update!(best_category_id: no_category.id)
      end

      it "creates a pending result for title categories (cat_id < 4) when better than best" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing)
        expect {
          processor.update_result
        }.to change(Result, :count).by(1)
        pending = Result.find_by(group_id: title_group.id)
        expect(pending).to be_present
        expect(pending.status).to eq(Result::PENDING)
        expect(pending.category_id).to eq(cat2.id)
      end

      it "caps the main result category_id to min(best_category, 4)" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing)
        processor.update_result
        expect(existing.reload.category_id).to be <= [ runner.best_category_id, 4 ].min
      end

      it "marks the capped main result with status CAPPED" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing)
        processor.update_result
        expect(existing.reload.status).to eq(Result::CAPPED)
      end

      it "links the pending row to the main result via parent_result_id" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing)
        processor.update_result
        pending = Result.find_by(group_id: title_group.id)
        expect(pending.parent_result_id).to eq(existing.id)
      end

      it "destroys the pending child when the main result is destroyed" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing)
        processor.update_result
        expect { existing.destroy! }.to change(Result, :count).by(-2) # main + linked pending
      end

      it "cascades at the DB level when the main result is deleted via raw SQL" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing)
        processor.update_result
        expect {
          Result.where(id: existing.id).delete_all # bypasses dependent: :destroy
        }.to change(Result, :count).by(-2)
      end

      it "clears stale child rows when the main result is updated to a different category" do
        ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing).update_result
        expect(existing.reload.child_results.count).to eq(1)

        # Second update bumps category to cat3 — old pending (cat2) should be replaced
        ResultProcessor.new({ runner_id: runner.id, category_id: cat3.id }, existing).update_result
        existing.reload
        expect(existing.child_results.count).to eq(1)
        expect(existing.child_results.first.category_id).to eq(cat3.id)
      end

      it "marks the main result CONFIRMED (not CAPPED) when no pending is created" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat4.id }, existing)
        processor.update_result
        expect(existing.reload.status).to eq(Result::CONFIRMED)
      end

      it "does not create pending for cat_id >= 4" do
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat4.id }, existing)
        expect {
          processor.update_result
        }.not_to change(Result, :count)
        expect(existing.reload.category_id).to eq(cat4.id)
      end

      it "does not create   pending when category is not better than best_category" do
        runner.update!(best_category_id: cat1.id)
        processor = ResultProcessor.new({ runner_id: runner.id, category_id: cat2.id }, existing)
        expect {
          processor.update_result
        }.not_to change(Result, :count)
        expect(existing.reload.category_id).to eq(cat2.id)
      end
    end

    context "with three results category (junior rule)" do
      let!(:junior_runner) do
        Runner.create!(
          club: club, category: no_category, best_category: no_category,
          runner_name: "Junior", surname: "Runner", gender: "M", yob: Time.now.year - 15
        )
      end
      let!(:junior_membership) { Membership.create!(runner: junior_runner, club: club) }

      before do
        # Two prior NO_CATEGORY results after the cutoff date; the result the
        # processor adds becomes the third one.
        2.times do |i|
          Result.create!(
            group: group, membership: junior_membership, category: no_category,
            date: Date.new(2024, 4, 1) + i.months, status: Result::UNCONFIRMED
          )
        end
      end

      it "creates a three-results category result for a junior NO_CATEGORY result" do
        params = build_params(runner_id: junior_runner.id, category_id: no_category.id, date: Date.new(2025, 6, 1))
        processor = ResultProcessor.new(params)
        # Pre-set membership_id on the params to bypass add_membership_id
        processor.params["membership_id"] = junior_membership.id
        allow(processor).to receive(:add_membership_id).and_return(junior_membership.id)
        expect {
          processor.add_result
        }.to change(Result, :count).by(2) # main + three_results
        three_result = Result.find_by(group_id: three_results_group.id, membership_id: junior_membership.id)
        expect(three_result).to be_present
        expect(three_result.category_id).to eq(9)
        expect(three_result.status).to eq(Result::CONFIRMED)
        expect(three_result.parent_result_id).to eq(processor.result.id)
      end

      it "does not create three-results for a categorized result" do
        params = build_params(runner_id: junior_runner.id, category_id: cat5.id, date: Date.new(2025, 6, 1))
        ResultProcessor.new(params).add_result
        expect(Result.where(group_id: three_results_group.id).count).to eq(0)
      end

      it "does not create three-results for non-junior runner" do
        2.times do |i|
          Result.create!(
            group: group, membership: membership, category: no_category,
            date: Date.new(2024, 4, 1) + i.months, status: Result::UNCONFIRMED
          )
        end
        ResultProcessor.new(build_params(category_id: no_category.id)).add_result
        expect(Result.where(group_id: three_results_group.id).count).to eq(0)
      end

      it "does not create three-results before cutoff date" do
        params = build_params(runner_id: junior_runner.id, category_id: no_category.id, date: Date.new(2024, 3, 20))
        ResultProcessor.new(params).add_result
        expect(Result.where(group_id: three_results_group.id).count).to eq(0)
      end

      it "does not create three-results with fewer than three results since cutoff" do
        junior_membership.results.destroy_all
        params = build_params(runner_id: junior_runner.id, category_id: no_category.id, date: Date.new(2025, 6, 1))
        ResultProcessor.new(params).add_result
        expect(Result.where(group_id: three_results_group.id).count).to eq(0)
      end
    end
  end
end
