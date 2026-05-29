require "rails_helper"

RSpec.describe ExpiredCategoryJob, type: :job do
  before { allow(TelegramNotifier).to receive(:notify).and_return(true) }

  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category"; c.points = 0; c.validaty_period = 2 } }
  let!(:cat3)        { Category.find_or_create_by!(id: 3) { |c| c.category_name = "КМС";  c.points = 200; c.validaty_period = 3 } }
  let!(:cat4)        { Category.find_or_create_by!(id: 4) { |c| c.category_name = "I";    c.points = 100; c.validaty_period = 2 } }
  let!(:cat5)        { Category.find_or_create_by!(id: 5) { |c| c.category_name = "II";   c.points = 50;  c.validaty_period = 2 } }
  let!(:cat6)        { Category.find_or_create_by!(id: 6) { |c| c.category_name = "III";  c.points = 25;  c.validaty_period = 2 } }
  let!(:cat7)        { Category.find_or_create_by!(id: 7) { |c| c.category_name = "Iю";   c.points = 20;  c.validaty_period = 2 } }
  let!(:cat9)        { Category.find_or_create_by!(id: 9) { |c| c.category_name = "IIIю"; c.points = 10;  c.validaty_period = 2 } }

  let!(:club)             { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Test Club" } }
  let!(:competition)      { Competition.create!(competition_name: "Test", date: Date.new(2020, 6, 1), distance_type: "Sprint") }
  let!(:reduction_group)  { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)         { |g| g.competition = competition; g.group_name = "REDUCTION" } }
  let!(:title_group)      { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }
  let!(:three_group)      { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)              { |g| g.competition = competition; g.group_name = "THREE" } }

  def build_runner(category:, category_valid:, yob: 2000, best_category: nil)
    runner = Runner.create!(
      club: club, category: category, best_category: best_category || category,
      runner_name: "R", surname: "X", gender: "M", yob: yob
    )
    Membership.create!(runner: runner, club: club)
    # Bypass update_runner_category — set the expired state directly.
    runner.update_columns(category_id: category.id, category_valid: category_valid)
    runner
  end

  describe "#perform demotion paths" do
    it "demotes a runner one category step by creating a reduction result" do
      runner = build_runner(category: cat5, category_valid: Date.today - 1)

      expect { described_class.new.perform }.to change(Result, :count).by(1)

      reduction = Result.find_by(group_id: reduction_group.id)
      expect(reduction.category_id).to eq(cat6.id)
      expect(reduction.date).to eq(Date.today)
      expect(reduction.status).to eq(Result::CONFIRMED)
    end

    it "demotes a КМС holder to I разряд without creating a pending child" do
      runner = build_runner(category: cat3, category_valid: Date.today - 1, best_category: cat3)

      expect { described_class.new.perform }.to change(Result, :count).by(1)

      reduction = Result.find_by(group_id: reduction_group.id)
      expect(reduction.category_id).to eq(cat4.id)
      expect(reduction.status).to eq(Result::CONFIRMED)
      expect(Result.where(group_id: title_group.id)).to be_empty
    end

    it "demotes a junior holder of III to Iю" do
      runner = build_runner(category: cat6, category_valid: Date.today - 1, yob: Date.today.year - 15)

      described_class.new.perform

      reduction = Result.find_by(group_id: reduction_group.id)
      expect(reduction).to be_present
      expect(reduction.category_id).to eq(cat7.id)
    end
  end

  describe "#perform skip paths" do
    it "creates no demotion result for an adult holder of III разряд" do
      runner = build_runner(category: cat6, category_valid: Date.today - 1, yob: 1990)

      expect { described_class.new.perform }.not_to change { Result.where(group_id: reduction_group.id).count }
    end

    it "drops an adult III holder to NO_CATEGORY via update_runner_category" do
      runner = build_runner(category: cat6, category_valid: Date.today - 1, yob: 1990)

      described_class.new.perform

      expect(runner.reload.category_id).to eq(Category::NO_CATEGORY_ID)
      expect(runner.category_valid).to eq(Date.new(2100, 1, 1))
    end

    it "creates no demotion result for a holder of IIIю" do
      runner = build_runner(category: cat9, category_valid: Date.today - 1, yob: Date.today.year - 16)

      expect { described_class.new.perform }.not_to change { Result.where(group_id: reduction_group.id).count }
      expect(runner.reload.category_id).to eq(Category::NO_CATEGORY_ID)
    end
  end

  describe "#perform scope" do
    it "ignores runners whose category_valid is in the future" do
      runner = build_runner(category: cat5, category_valid: Date.today + 30)

      expect { described_class.new.perform }.not_to change(Result, :count)
      expect(runner.reload.category_id).to eq(cat5.id)
    end

    it "processes every runner found at job start even if state shifts mid-loop" do
      expired_a = build_runner(category: cat5, category_valid: Date.today - 1)
      expired_b = build_runner(category: cat5, category_valid: Date.today - 1)

      expect { described_class.new.perform }.to change(Result, :count).by(2)
      expect(Result.where(group_id: reduction_group.id).count).to eq(2)
    end
  end

  describe "#perform end-of-job runner refresh" do
    it "calls update_runner_category on every originally-expired runner" do
      runner = build_runner(category: cat5, category_valid: Date.today - 1)

      described_class.new.perform

      runner.reload
      expect(runner.category_id).to eq(cat6.id)
      expect(runner.category_valid).to be > Date.today
    end
  end

  describe "#perform Telegram notification" do
    it "notifies Telegram with the runners whose category actually changed" do
      runner = build_runner(category: cat5, category_valid: Date.today - 1)

      captured = nil
      expect(TelegramExpiredCategoryNotifier).to receive(:notify) { |changes| captured = changes; 1 }

      described_class.new.perform

      expect(captured.size).to eq(1)
      change = captured.first
      expect(change[:runner].id).to eq(runner.id)
      expect(change[:old_category_id]).to eq(cat5.id)
      expect(change[:new_category_id]).to eq(cat6.id)
    end

    it "does not notify when nothing changed" do
      build_runner(category: cat5, category_valid: Date.today + 30)

      expect(TelegramExpiredCategoryNotifier).not_to receive(:notify)

      described_class.new.perform
    end

    it "still notifies for runners demoted to NO_CATEGORY (adult III holders)" do
      runner = build_runner(category: cat6, category_valid: Date.today - 1, yob: 1990)

      captured = nil
      expect(TelegramExpiredCategoryNotifier).to receive(:notify) { |changes| captured = changes; 1 }

      described_class.new.perform

      change = captured.find { |c| c[:runner].id == runner.id }
      expect(change).to be_present
      expect(change[:old_category_id]).to eq(cat6.id)
      expect(change[:new_category_id]).to eq(Category::NO_CATEGORY_ID)
    end

    it "swallows Telegram errors so the job still completes" do
      runner = build_runner(category: cat5, category_valid: Date.today - 1)

      expect(TelegramExpiredCategoryNotifier).to receive(:notify).and_raise(StandardError, "network down")
      expect(Rails.logger).to receive(:error).with(/Telegram notification failed/)

      expect { described_class.new.perform }.not_to raise_error
      expect(runner.reload.category_id).to eq(cat6.id)
    end
  end
end
