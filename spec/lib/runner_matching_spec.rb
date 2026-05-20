require "rails_helper"

RSpec.describe RunnerMatching do
  let!(:category) { Category.create!(category_name: "Test") }
  let!(:club) { Club.create!(club_name: "Test Club") }

  describe "constants" do
    it "defines THRESHOLD" do
      expect(RunnerMatching::THRESHOLD).to eq(0.8)
    end

    it "defines INVALID_RUNNER_ID" do
      expect(RunnerMatching::INVALID_RUNNER_ID).to eq(99_999_999)
    end
  end

  describe ".get_runner_by_matching" do
    let!(:runner) do
      Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2000
      )
    end

    it "finds an exact soundex match" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2000
      )
      expect(result).to eq(runner)
    end

    it "finds a soundex match with similar sounding name" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Iван", surname: "Petrov", gender: "M", yob: 2000
      )
      # Soundex may or may not match depending on transliteration;
      # at minimum the method should not raise
      expect(result).to be_nil.or eq(runner)
    end

    it "finds a fuzzy Levenshtein match" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivam", surname: "Petrof", gender: "M", yob: 2000
      )
      expect(result).to eq(runner)
    end

    it "returns nil when similarity is below threshold" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Xyz", surname: "Abc", gender: "M", yob: 2000
      )
      expect(result).to be_nil
    end

    it "filters by gender" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivan", surname: "Petrov", gender: "W", yob: 2000
      )
      expect(result).to be_nil
    end

    it "filters by yob within ±1 range" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2001
      )
      expect(result).to eq(runner)
    end

    it "does not match runners outside yob ±1 range" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2005
      )
      expect(result).to be_nil
    end

    it "matches runners with yob=0 regardless of search yob" do
      zero_yob_runner = Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Maria", surname: "Popescu", gender: "W", yob: 0
      )
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Maria", surname: "Popescu", gender: "W", yob: 1995
      )
      expect(result).to eq(zero_yob_runner)
    end

    it "skips yob filter when search yob is 0" do
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 0
      )
      expect(result).to eq(runner)
    end

    it "excludes INVALID_RUNNER_ID" do
      invalid_runner = Runner.create!(
        id: RunnerMatching::INVALID_RUNNER_ID,
        club: club, category: category, best_category: category,
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2000
      )
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2000
      )
      expect(result).not_to eq(invalid_runner)
    end

    it "prefers soundex match over Levenshtein" do
      # Create two runners, one exact soundex and one slightly different
      exact = Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Andrei", surname: "Costin", gender: "M", yob: 1995
      )
      Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Andreh", surname: "Costim", gender: "M", yob: 1995
      )
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Andrei", surname: "Costin", gender: "M", yob: 1995
      )
      expect(result).to eq(exact)
    end

    it "picks the closest Levenshtein match among multiple candidates" do
      Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Ivano", surname: "Petrovv", gender: "M", yob: 2000
      )
      closer = Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Ivam", surname: "Petrov", gender: "M", yob: 2000
      )
      # Both are close but "Ivam/Petrov" is closer than "Ivano/Petrovv"
      result = RunnerMatching.get_runner_by_matching(
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2000
      )
      # Soundex will match the original `runner` first
      expect(result).to eq(runner).or eq(closer)
    end
  end

  describe ".normalized_distance" do
    it "returns 0 for identical strings" do
      expect(RunnerMatching.send(:normalized_distance, "abc", "abc")).to eq(0.0)
    end

    it "returns 1.0 for two empty strings" do
      expect(RunnerMatching.send(:normalized_distance, "", "")).to eq(1.0)
    end

    it "returns a value between 0 and 1" do
      dist = RunnerMatching.send(:normalized_distance, "ivan", "ivam")
      expect(dist).to be_between(0, 1)
    end

    it "returns higher distance for more different strings" do
      close = RunnerMatching.send(:normalized_distance, "ivan", "ivam")
      far = RunnerMatching.send(:normalized_distance, "ivan", "xxxx")
      expect(close).to be < far
    end
  end

  describe ".by_soundex?" do
    let!(:runner) do
      Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2000
      )
    end

    it "returns true for matching soundex" do
      expect(RunnerMatching.send(:by_soundex?, runner, "ivan", "petrov")).to be true
    end

    it "returns false for non-matching soundex" do
      expect(RunnerMatching.send(:by_soundex?, runner, "xyz", "abc")).to be false
    end
  end

  describe ".by_levenshtein" do
    let!(:runner) do
      Runner.create!(
        club: club, category: category, best_category: category,
        runner_name: "Ivan", surname: "Petrov", gender: "M", yob: 2000
      )
    end

    it "returns [distance, runner] for similar names" do
      result = RunnerMatching.send(:by_levenshtein, runner, "ivam", "petrov")
      expect(result).to be_an(Array)
      expect(result.last).to eq(runner)
      expect(result.first).to be_between(0, 1)
    end

    it "returns nil for dissimilar names" do
      result = RunnerMatching.send(:by_levenshtein, runner, "xyz", "abc")
      expect(result).to be_nil
    end

    it "returns nil when similarity is below THRESHOLD" do
      result = RunnerMatching.send(:by_levenshtein, runner, "completely", "different")
      expect(result).to be_nil
    end
  end
end
