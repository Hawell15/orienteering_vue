require "rails_helper"

RSpec.describe RelayGroupCategoriesProcessor do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }

  # Ensure the seeded categories carry the points the rang tables expect.
  let!(:cat1)  { Category.find(1).tap  { |c| c.update!(category_name: "MISRM", points: 300, validaty_period: 4) } }
  let!(:cat2)  { Category.find(2).tap  { |c| c.update!(category_name: "MSRM",  points: 200, validaty_period: 3) } }
  let!(:cat3)  { Category.find(3).tap  { |c| c.update!(category_name: "CMSRM", points: 150, validaty_period: 3) } }
  let!(:cat4)  { Category.find(4).tap  { |c| c.update!(category_name: "I",     points: 100, validaty_period: 2) } }
  let!(:cat5)  { Category.find(5).tap  { |c| c.update!(category_name: "II",    points:  50, validaty_period: 2) } }
  let!(:cat6)  { Category.find(6).tap  { |c| c.update!(category_name: "III",   points:  30, validaty_period: 2) } }
  let!(:cat7)  { Category.find(7).tap  { |c| c.update!(category_name: "I j",   points:  20, validaty_period: 2) } }
  let!(:cat10) { Category.find(10).tap { |c| c.update!(category_name: "f/c",   points:   0, validaty_period: 2) } }

  let!(:competition) do
    Competition.create!(
      competition_name: "Classic Relay",
      date:             Date.new(2026, 5, 2),
      distance_type:    "Ștafetă clasică",
      country:          "Moldova"
    )
  end

  # A prior competition used solely to seed each runner's category history.
  # The relay group's `get_group_rang` reads via `runner.category_on_date(comp.date)`,
  # which queries confirmed Results dated strictly before that date.
  let!(:prior_competition) do
    Competition.create!(competition_name: "Prior", date: competition.date - 6.months, distance_type: "Sprint")
  end
  let!(:prior_group) { Group.create!(competition: prior_competition, group_name: "PRIOR") }

  let!(:reduction_group)     { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)         { |g| g.competition = competition; g.group_name = "REDUCTION" } }
  let!(:title_group)         { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }
  let!(:three_results_group) { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)              { |g| g.competition = competition; g.group_name = "THREE" } }
  let!(:group)               { Group.create!(competition: competition, group_name: "M21", clasa: "4") }

  def make_runner(name:, yob: 1990, category: cat4)
    runner     = Runner.create!(club: club, runner_name: name, surname: "X", gender: "M", yob: yob, category: category, best_category: category, category_valid: Date.new(2099, 1, 1))
    membership = Membership.find_or_create_by!(runner: runner, club: club)

    # Seed prior confirmed result so `category_on_date(competition.date)` returns this category.
    Result.create!(
      group:           prior_group,
      membership:      membership,
      category:        category,
      date:            prior_competition.date,
      time:            3000,
      place:           1,
      status:          Result::CONFIRMED,
      skip_processing: true
    )

    runner
  end

  def make_leg(runner, time:, place:)
    membership = Membership.find_or_create_by!(runner: runner, club: club)
    Result.create!(
      group:           group,
      membership:      membership,
      category_id:     Category::NO_CATEGORY_ID,
      date:            competition.date,
      time:            time,
      place:           place,
      status:          Result::CONFIRMED,
      skip_processing: true
    )
  end

  # Build an N-leg team (N = runners.size), return the RelayResult.
  def make_team(runners, place:, time:)
    legs = runners.map { |r| make_leg(r, time: time / runners.size, place: place) }
    RelayResult.create!(
      group:       group,
      category_id: Category::NO_CATEGORY_ID,
      team:        "Team #{place}",
      place:       place,
      time:        time,
      date:        competition.date,
      results_id:  legs.map(&:id)
    )
  end

  def runners_for(prefix, count, category: cat2)
    count.times.map { |i| make_runner(name: "#{prefix}#{i}", category: category) }
  end

  describe "#main_results / #winner_time" do
    it "uses the group's relay_results ordered by place" do
      t1 = make_team(runners_for("A", 3), place: 1, time: 5400)
      _t2 = make_team(runners_for("B", 3), place: 2, time: 6000)

      processor = described_class.new(group)
      expect(processor.main_results.first).to eq(t1)
      expect(processor.winner_time).to eq(5400)
    end
  end

  describe "#rang_results" do
    it "returns the leg Results of the top 4 teams for classic relay" do
      5.times { |i| make_team(runners_for("P#{i}_", 3), place: i + 1, time: 5400 + i * 60) }

      processor = described_class.new(group)
      expect(processor.rang_results.size).to eq(12) # 4 top teams × 3 legs
    end

    it "returns top 3 teams for sprint relay (4 legs each)" do
      competition.update!(distance_type: "Ștafetă sprint")
      4.times { |i| make_team(runners_for("S#{i}_", 4), place: i + 1, time: 5400) }

      processor = described_class.new(group)
      expect(processor.rang_results.size).to eq(12) # 3 top teams × 4 legs
    end
  end

  describe "#set_junior_category?" do
    it "is true when all legs' runners are junior on competition date" do
      juniors = 3.times.map { |i| make_runner(name: "J#{i}", yob: competition.date.year - 15, category: cat7) }
      team    = make_team(juniors, place: 1, time: 5400)

      expect(described_class.new(group).set_junior_category?(team)).to be true
    end

    it "is false when at least one leg's runner is adult" do
      mixed = [
        make_runner(name: "J",  yob: competition.date.year - 15, category: cat7),
        make_runner(name: "A",  yob: competition.date.year - 30, category: cat4),
        make_runner(name: "J2", yob: competition.date.year - 16, category: cat7)
      ]
      team = make_team(mixed, place: 1, time: 5400)

      expect(described_class.new(group).set_junior_category?(team)).to be false
    end
  end

  describe "#get_rang_and_categories" do
    before do
      4.times { |i| make_team(runners_for("M#{i}_", 3, category: cat2), place: i + 1, time: 5400 + i * 60) }
    end

    it "computes rang from prior-confirmed-result category points (4 teams × 3 legs × 200 pts = 2400)" do
      described_class.new(group).get_rang_and_categories
      expect(group.reload.rang).to eq(2400)
    end

    it "writes the earned category onto the RelayResult" do
      described_class.new(group).get_rang_and_categories
      winner = group.relay_results.order(:place).first
      expect(winner.reload.category_id).not_to eq(Category::NO_CATEGORY_ID)
    end

    it "propagates the earned category onto each leg Result" do
      described_class.new(group).get_rang_and_categories
      winner = group.relay_results.order(:place).first.reload
      winner.results_id.each do |leg_id|
        expect(Result.find(leg_id).category_id).to eq(winner.category_id)
      end
    end

    it "skips category assignment when the group has fewer than min_results_size teams" do
      group.relay_results.destroy_all
      Result.where(group_id: group.id).destroy_all
      make_team(runners_for("Solo_", 3), place: 1, time: 5400)

      described_class.new(group).get_rang_and_categories
      relay = RelayResult.find_by(group_id: group.id)
      expect(relay.category_id).to eq(Category::NO_CATEGORY_ID)
    end
  end

  describe "#get_percent_and_times" do
    it "returns category/percent/time rows once the group has enough teams" do
      4.times { |i| make_team(runners_for("Q#{i}_", 3, category: cat2), place: i + 1, time: 5400 + i * 60) }

      described_class.new(group).get_rang_and_categories
      rows = described_class.new(group).get_percent_and_times
      expect(rows).not_to be_empty
      expect(rows.first.keys.sort).to eq([ :category, :percent, :time ])
    end
  end
end
