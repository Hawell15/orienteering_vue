require "rails_helper"

RSpec.describe GroupPlaceReorderer do
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "No Category"; c.points = 0; c.validaty_period = 2 } }
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:competition) { Competition.create!(competition_name: "Test", date: Date.new(2025, 6, 1), distance_type: "Sprint") }
  let!(:group) { Group.create!(competition: competition, group_name: "M21") }
  let!(:other_group) { Group.create!(competition: competition, group_name: "W21") }

  def make_runner(name = "R#{SecureRandom.hex(2)}")
    Runner.create!(club: club, runner_name: name, surname: "X", gender: "M", yob: 2000)
  end

  def make_result(grp, time:, place: nil, parent_result_id: nil)
    Result.create!(
      group:            grp,
      membership:       Membership.create!(runner: make_runner, club: club),
      category_id:      no_category.id,
      date:             competition.date,
      time:             time,
      place:            place,
      parent_result_id: parent_result_id,
      skip_processing:  true
    )
  end

  describe "#call" do
    it "ranks timed results by ascending time" do
      a = make_result(group, time: 3000, place: 1)
      b = make_result(group, time: 1500, place: 2)
      c = make_result(group, time: 2200, place: 3)

      GroupPlaceReorderer.new(group).call

      expect(a.reload.place).to eq(3)
      expect(b.reload.place).to eq(1)
      expect(c.reload.place).to eq(2)
    end

    it "sets place to nil for results with time = 0" do
      r = make_result(group, time: 0, place: 5)
      GroupPlaceReorderer.new(group).call
      expect(r.reload.place).to be_nil
    end

    it "sets place to nil for results with time = nil" do
      r = make_result(group, time: nil, place: 5)
      GroupPlaceReorderer.new(group).call
      expect(r.reload.place).to be_nil
    end

    it "ranks timed results around untimed ones (untimed are excluded)" do
      make_result(group, time: nil, place: 99)
      first  = make_result(group, time: 1000, place: 10)
      second = make_result(group, time: 2000, place: 11)

      GroupPlaceReorderer.new(group).call

      expect(first.reload.place).to eq(1)
      expect(second.reload.place).to eq(2)
    end

    it "does not touch results in other groups" do
      other = make_result(other_group, time: 5000, place: 7)
      make_result(group, time: 1000, place: 1)

      GroupPlaceReorderer.new(group).call

      expect(other.reload.place).to eq(7)
    end

    it "does not touch child results (parent_result_id present)" do
      parent = make_result(group, time: 1000, place: 1)
      child  = Result.create!(
        group:            group,
        membership:       parent.membership,
        category_id:      no_category.id,
        date:             competition.date,
        place:            42,
        time:             0,
        parent_result_id: parent.id,
        status:           Result::PENDING,
        skip_processing:  true
      )

      GroupPlaceReorderer.new(group).call

      expect(child.reload.place).to eq(42)
    end

    it "is idempotent" do
      a = make_result(group, time: 1000)
      b = make_result(group, time: 2000)
      c = make_result(group, time: 3000)

      2.times { GroupPlaceReorderer.new(group).call }

      expect([ a.reload.place, b.reload.place, c.reload.place ]).to eq([ 1, 2, 3 ])
    end

    it "does not trigger the categorizer (place change only)" do
      result = make_result(group, time: 5000, place: 99)
      expect_any_instance_of(ResultCategorizer).not_to receive(:before_save)
      GroupPlaceReorderer.new(group).call
      expect(result.reload.place).to eq(1)
    end
  end
end
