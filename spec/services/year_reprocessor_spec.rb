require "rails_helper"

RSpec.describe YearReprocessor do
  # A fully-past year keeps the replay timeline behind Date.today, matching
  # the retroactive use case.
  let(:year) { Date.today.year - 1 }

  # The test DB may hold category rows left by other specs; force the
  # attributes inside the example transaction.
  def ensure_category(id, name, points, validity)
    category = Category.find_or_create_by!(id: id) { |c| c.category_name = name; c.points = points; c.validaty_period = validity }
    category.update_columns(category_name: name, points: points, validaty_period: validity)
    category
  end

  let!(:no_category) { ensure_category(Category::NO_CATEGORY_ID, "f/c", 0, 2) }
  let!(:cat2)        { ensure_category(2, "MSRM",  100, 3) }
  let!(:cat3)        { ensure_category(3, "CMSRM", 30,  3) }
  let!(:cat4)        { ensure_category(4, "I",     10,  2) }
  let!(:cat5)        { ensure_category(5, "II",    4,   2) }
  let!(:cat6)        { ensure_category(6, "III",   2,   2) }
  let!(:cat7)        { ensure_category(7, "I j",   1,   2) }
  let!(:cat9)        { ensure_category(9, "III j", 0.3, 2) }

  let!(:club)            { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Test Club" } }
  let!(:special_comp)    { Competition.create!(competition_name: "Special", date: Date.new(2020, 6, 1), distance_type: "Sprint") }
  let!(:no_group)        { Group.find_or_create_by!(id: Group::NO_GROUP_ID)                          { |g| g.competition = special_comp; g.group_name = "NOGROUP" } }
  let!(:reduction_group) { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)          { |g| g.competition = special_comp; g.group_name = "REDUCTION" } }
  let!(:three_group)     { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)               { |g| g.competition = special_comp; g.group_name = "THREE" } }
  let!(:title_group)     { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID)  { |g| g.competition = special_comp; g.group_name = "TITLE" } }

  let!(:comp0) { Competition.create!(competition_name: "PreYear",  date: Date.new(year - 1, 12, 1), distance_type: "Sprint") }
  let!(:comp1) { Competition.create!(competition_name: "First",    date: Date.new(year, 2, 20),     distance_type: "Sprint") }
  let!(:comp2)    { Competition.create!(competition_name: "Second",  date: Date.new(year, 3, 15), distance_type: "Medie") }
  let!(:comp_wre) { Competition.create!(competition_name: "WRE Race", date: Date.new(year, 3, 20), distance_type: "Sprint", wre_id: 9999) }

  let!(:group0)   { Group.create!(competition: comp0, group_name: "M0",  clasa: "10") }
  let!(:g_solo)   { Group.create!(competition: comp1, group_name: "M14", clasa: "10") }
  let!(:g_thresh) { Group.create!(competition: comp1, group_name: "M21", clasa: "5") }
  let!(:g_cap)    { Group.create!(competition: comp1, group_name: "W21", clasa: "3") }
  let!(:g_empty)  { Group.create!(competition: comp2, group_name: "M2",  clasa: "10") }
  let!(:g_wre)    { Group.create!(competition: comp_wre, group_name: "M21E", rang: 500) }

  def create_runner(name, yob: 1990)
    runner = Runner.create!(club: club, category: no_category, best_category: no_category,
                            runner_name: name, surname: "T", gender: "M", yob: yob)
    Membership.create!(runner: runner, club: club)
    runner
  end

  # Fixture rows bypass the categorizer so each example controls state exactly.
  def add_result(runner, group:, category:, status:, date: nil, place: nil, time: nil, wre_points: nil)
    result = Result.new(membership: runner.memberships.first, group: group, category: category,
                        status: status, date: date, place: place, time: time, wre_points: wre_points)
    result.skip_processing = true
    result.save!
    result
  end

  let!(:runner_a) { create_runner("A") }
  let!(:runner_b) { create_runner("B") }
  let!(:runner_c) { create_runner("C") }
  let!(:runner_d) { create_runner("D") }
  let!(:runner_e) { create_runner("E") }
  let!(:runner_f) { create_runner("F") }
  let!(:runner_g) { create_runner("G") }
  let!(:runner_h) { create_runner("H") }
  let!(:runner_s) { create_runner("S") }
  let!(:runner_j) { create_runner("J", yob: year - 15) }
  let!(:runner_k) { create_runner("K") }
  let!(:runner_w1) { create_runner("W1") }
  let!(:runner_w2) { create_runner("W2") }

  before do
    # Pre-year earned categories (still valid through the replayed year).
    [ runner_a, runner_b, runner_c ].each { |r| add_result(r, group: group0, category: cat6, status: Result::CONFIRMED) }
    add_result(runner_f, group: group0, category: cat4, status: Result::CONFIRMED)
    [ runner_g, runner_h ].each { |r| add_result(r, group: group0, category: cat2, status: Result::CONFIRMED) }
    # D's II разряд expires between comp1 and comp2.
    add_result(runner_d, group: group0, category: cat5, status: Result::CONFIRMED, date: Date.new(year - 2, 3, 1))

    # Ministry order entered manually mid-February of the replayed year.
    add_result(runner_e, group: no_group, category: cat3, status: Result::CONFIRMED, date: Date.new(year, 2, 9))
    add_result(runner_e, group: group0, category: cat4, status: Result::CONFIRMED)

    # Stale artifacts from the previous (wrong) processing run.
    add_result(runner_d, group: reduction_group, category: cat6, status: Result::CONFIRMED, date: Date.new(year, 1, 15))

    # Junior J's earlier starts — the third result in comp1 triggers the
    # three-results promotion.
    add_result(runner_j, group: group0, category: no_category, status: Result::UNCONFIRMED, place: 5, time: 5000)
    add_result(runner_j, group: group0, category: no_category, status: Result::UNCONFIRMED, place: 6, time: 6000, date: Date.new(year - 1, 12, 2))

    # Competition results of the replayed year (state as freshly imported).
    add_result(runner_s, group: g_solo, category: no_category, status: Result::UNCONFIRMED, place: 1, time: 1000)
    add_result(runner_j, group: g_solo, category: no_category, status: Result::UNCONFIRMED, place: 2, time: 2000)

    add_result(runner_a, group: g_thresh, category: no_category, status: Result::UNCONFIRMED, place: 1, time: 1000)
    add_result(runner_b, group: g_thresh, category: no_category, status: Result::UNCONFIRMED, place: 2, time: 1150)
    add_result(runner_c, group: g_thresh, category: no_category, status: Result::UNCONFIRMED, place: 3, time: 3000)

    # K carries a manual admin category assignment (capped with a pending
    # title child) that time-based replay cannot recompute.
    k_result = add_result(runner_k, group: g_solo, category: cat4, status: Result::CAPPED, place: 3, time: 3000)
    child = Result.new(membership: runner_k.memberships.first, group: title_group, category: cat3,
                       status: Result::PENDING, date: k_result.date, parent_result: k_result)
    child.skip_processing = true
    child.save!

    # WRE race results — categories must come from WRE points, not thresholds.
    add_result(runner_w1, group: g_wre, category: no_category, status: Result::UNCONFIRMED, place: 1, time: 900, wre_points: 1100)
    add_result(runner_w2, group: g_wre, category: no_category, status: Result::UNCONFIRMED, place: 2, time: 950, wre_points: 800)

    add_result(runner_f, group: g_cap, category: no_category, status: Result::UNCONFIRMED, place: 1, time: 1000)
    add_result(runner_g, group: g_cap, category: no_category, status: Result::UNCONFIRMED, place: 2, time: 1100)
    add_result(runner_h, group: g_cap, category: no_category, status: Result::UNCONFIRMED, place: 3, time: 1200)
  end

  def run!
    described_class.new(year, io: StringIO.new).call
  end

  it "wipes stale statuses that the replay does not re-confirm" do
    solo = Result.find_by(group_id: g_solo.id)
    solo.update_columns(status: Result::CONFIRMED, category_id: cat5.id)

    run!

    solo.reload
    expect(solo.status).to eq(Result::UNCONFIRMED)
    expect(solo.category_id).to eq(Category::NO_CATEGORY_ID)
  end

  it "recomputes rang and confirms results per the time thresholds" do
    run!

    expect(g_thresh.reload.rang).to eq(6)

    a = Result.find_by(group_id: g_thresh.id, place: 1)
    b = Result.find_by(group_id: g_thresh.id, place: 2)
    c = Result.find_by(group_id: g_thresh.id, place: 3)

    expect(a.category_id).to eq(cat6.id)
    expect(a.status).to eq(Result::CONFIRMED)
    # B's time lands on a junior-only rank; adults fall back to no category.
    expect(b.category_id).to eq(Category::NO_CATEGORY_ID)
    expect(b.status).to eq(Result::UNCONFIRMED)
    expect(c.category_id).to eq(Category::NO_CATEGORY_ID)
  end

  it "replaces stale reductions with one simulated at the correct expiry between competitions" do
    run!

    reductions = Result.joins(:membership).where(group_id: reduction_group.id, memberships: { runner_id: runner_d.id })
    expect(reductions.count).to eq(1)
    expect(reductions.first.date).to eq(Date.new(year, 3, 2))
    expect(reductions.first.category_id).to eq(cat6.id)
    expect(reductions.first.status).to eq(Result::CONFIRMED)
    expect(runner_d.reload.category_id).to eq(cat6.id)
  end

  it "keeps manual ministry confirmations and feeds them into the runner cache and best-category ratchet" do
    run!

    ministry = Result.find_by(group_id: no_group.id, date: Date.new(year, 2, 9))
    expect(ministry.status).to eq(Result::CONFIRMED)

    runner_e.reload
    expect(runner_e.category_id).to eq(cat3.id)
    expect(runner_e.best_category_id).to eq(cat3.id)
    expect(runner_e.category_valid).to eq(Date.new(year, 2, 9) + cat3.validaty_period.years)
  end

  it "re-creates capped results with their pending title children" do
    run!

    expect(g_cap.reload.rang).to eq(210)

    f = Result.find_by(group_id: g_cap.id, place: 1)
    expect(f.status).to eq(Result::CAPPED)
    expect(f.category_id).to eq(cat4.id)

    child = f.child_results.find_by(group_id: title_group.id)
    expect(child).to be_present
    expect(child.category_id).to eq(cat3.id)
    expect(child.status).to eq(Result::PENDING)
  end

  it "re-creates three-results junior promotions for results left without category" do
    run!

    j_result = Result.find_by(group_id: g_solo.id, place: 2)
    expect(j_result.status).to eq(Result::UNCONFIRMED)
    expect(j_result.category_id).to eq(Category::NO_CATEGORY_ID)

    child = j_result.child_results.find_by(group_id: three_group.id)
    expect(child).to be_present
    expect(child.category_id).to eq(cat9.id)
    expect(child.status).to eq(Result::CONFIRMED)
    expect(runner_j.reload.category_id).to eq(cat9.id)
  end

  it "preserves manual admin category assignments the replay cannot recompute" do
    run!

    k = Result.find_by(group_id: g_solo.id, place: 3)
    expect(k.status).to eq(Result::CAPPED)
    expect(k.category_id).to eq(cat4.id)

    child = k.child_results.find_by(group_id: title_group.id)
    expect(child).to be_present
    expect(child.category_id).to eq(cat3.id)
    expect(child.status).to eq(Result::PENDING)
  end

  it "categorizes WRE competitions from wre_points and leaves their rang unset" do
    run!

    expect(g_wre.reload.rang).to be_nil

    w1 = Result.find_by(group_id: g_wre.id, place: 1)
    # 1100 WRE points → MSRM, capped at I разряд with a pending title child.
    expect(w1.status).to eq(Result::CAPPED)
    expect(w1.category_id).to eq(cat4.id)
    expect(w1.child_results.find_by(group_id: title_group.id).category_id).to eq(cat2.id)

    w2 = Result.find_by(group_id: g_wre.id, place: 2)
    # 800 WRE points → I разряд, confirmed directly.
    expect(w2.status).to eq(Result::CONFIRMED)
    expect(w2.category_id).to eq(cat4.id)
    expect(runner_w2.reload.category_id).to eq(cat4.id)
  end

  it "rolls back the best-category ratchet to the pre-year state before replaying" do
    # Simulate a wrongly-earned title from the previous processing run.
    runner_s.update_columns(best_category_id: 2)

    run!

    expect(runner_s.reload.best_category_id).to eq(Category::NO_CATEGORY_ID)
  end
end
