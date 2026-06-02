require "rails_helper"

RSpec.describe TelegramCompetitionNotifier do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Olimp" } }
  let!(:other_club) { Club.create!(club_name: "Atlas") }
  let!(:competition) do
    Competition.create!(
      competition_name: "Cupa & Stafetă",
      date:             Date.new(2026, 5, 1),
      distance_type:    "Sprint",
      location:         "Chișinău"
    )
  end
  let!(:reduction_group)     { Group.find_or_create_by!(id: Group::REDUCTION_CATEGORY_GROUP_ID)         { |g| g.competition = competition; g.group_name = "REDUCTION" } }
  let!(:three_results_group) { Group.find_or_create_by!(id: Group::THREE_RESULTS_GROUP_ID)              { |g| g.competition = competition; g.group_name = "THREE" } }
  let!(:title_group)         { Group.find_or_create_by!(id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID) { |g| g.competition = competition; g.group_name = "TITLE" } }
  let!(:men_group)   { Group.create!(competition: competition, group_name: "M21") }
  let!(:women_group) { Group.create!(competition: competition, group_name: "W21") }

  def make_result(grp:, club_for_membership:, name:, surname:, yob:, cat_id:, status:)
    runner = Runner.create!(
      club: club_for_membership, runner_name: name, surname: surname,
      gender: "M", yob: yob, best_category_id: cat_id
    )
    membership = Membership.create!(runner: runner, club: club_for_membership)
    Result.create!(
      group:        grp,
      membership:   membership,
      category_id:  cat_id,
      date:         competition.date,
      time:         3000,
      place:        1,
      status:       status,
      skip_processing: true
    )
  end

  before { allow(TelegramNotifier).to receive(:notify).and_return(true) }

  describe ".notify" do
    context "when no confirmed/capped results exist" do
      it "sends nothing and returns 0" do
        make_result(grp: men_group, club_for_membership: club, name: "John", surname: "Doe", yob: 2000, cat_id: 5, status: Result::UNCONFIRMED)
        expect(TelegramNotifier).not_to receive(:notify)
        expect(described_class.notify(competition)).to eq(0)
      end
    end

    context "with confirmed and capped results" do
      let!(:confirmed) { make_result(grp: men_group, club_for_membership: club, name: "Ion", surname: "Pop", yob: 2005, cat_id: 4, status: Result::CONFIRMED) }
      let!(:capped)    { make_result(grp: women_group, club_for_membership: other_club, name: "Ana", surname: "Marin", yob: 2003, cat_id: 4, status: Result::CAPPED) }
      let!(:unconfirmed) { make_result(grp: men_group, club_for_membership: club, name: "Skip", surname: "Me", yob: 2000, cat_id: 5, status: Result::UNCONFIRMED) }

      it "sends one message per group with reportable results" do
        described_class.notify(competition, host: "https://example.com")
        expect(TelegramNotifier).to have_received(:notify).twice
      end

      it "includes a clickable competition link when host is provided" do
        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        described_class.notify(competition, host: "https://example.com")

        expect(captured.first).to include(%(<a href="https://example.com/competitions/#{competition.id}">))
      end

      it "escapes HTML-special characters in competition name" do
        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        described_class.notify(competition)

        expect(captured.first).to include("Cupa &amp; Stafetă")
      end

      it "passes parse_mode HTML to the underlying notifier" do
        described_class.notify(competition)
        expect(TelegramNotifier).to have_received(:notify).with(anything, parse_mode: "HTML").at_least(:once)
      end

      it "labels confirmed and capped statuses in Romanian" do
        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        described_class.notify(competition)

        joined = captured.join("\n")
        expect(joined).to include("(confirmat)")
        expect(joined).to include("(plafonat)")
      end

      it "includes runner name, yob, and club_name from the membership" do
        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        described_class.notify(competition)

        joined = captured.join("\n")
        expect(joined).to include("Ion Pop, 2005, Olimp")
        expect(joined).to include("Ana Marin, 2003, Atlas")
      end

      it "excludes results in special groups (parent_result_id will be present) and unconfirmed ones" do
        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        described_class.notify(competition)

        expect(captured.join).not_to include("Skip Me")
      end

      it "skips groups that have no reportable results" do
        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        described_class.notify(competition)

        expect(captured.size).to eq(2)
        expect(captured.any? { |m| m.include?("M21") }).to be true
        expect(captured.any? { |m| m.include?("W21") }).to be true
        expect(captured.any? { |m| m.include?("REDUCTION") }).to be false
      end
    end

    context "when a group has more results than fit in a single message" do
      before do
        stub_const("TelegramNotifier::MAX_MESSAGE_LENGTH", 250)
        6.times do |i|
          make_result(grp: men_group, club_for_membership: club, name: "Runner#{i}", surname: "X#{i}", yob: 2000, cat_id: 4, status: Result::CONFIRMED)
        end
      end

      it "splits into multiple chunks and marks continuations" do
        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        sent = described_class.notify(competition)

        expect(sent).to be > 1
        expect(captured.size).to be > 1
        expect(captured.drop(1).any? { |m| m.include?("(continuare)") }).to be true
        expect(captured.all? { |m| m.length <= TelegramNotifier::MAX_MESSAGE_LENGTH }).to be true
      end
    end

    context "with a relay competition" do
      let!(:relay_competition) do
        Competition.create!(
          competition_name: "Cupa Ștafetă",
          date:             Date.new(2026, 5, 2),
          distance_type:    "Ștafetă clasică",
          location:         "Chișinău"
        )
      end
      let!(:relay_group) { Group.create!(competition: relay_competition, group_name: "M21S") }

      def make_leg(name:, status:, cat_id: 4)
        runner = Runner.create!(
          club: club, runner_name: name, surname: "X",
          gender: "M", yob: 2000, best_category_id: cat_id
        )
        membership = Membership.create!(runner: runner, club: club)
        Result.create!(
          group:           relay_group,
          membership:      membership,
          category_id:     cat_id,
          date:            relay_competition.date,
          time:            1800,
          place:           1,
          status:          status,
          skip_processing: true
        )
      end

      it "sends per-leg lines (the individual runners), not a team aggregate" do
        leg1 = make_leg(name: "Ion",   status: Result::CONFIRMED)
        leg2 = make_leg(name: "Mihai", status: Result::CONFIRMED)
        leg3 = make_leg(name: "Andrei", status: Result::CAPPED)
        RelayResult.create!(
          group:       relay_group,
          category_id: 4,
          team:        "MDA-1",
          place:       1,
          time:        5400,
          date:        relay_competition.date,
          results_id:  [ leg1.id, leg2.id, leg3.id ]
        )

        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        described_class.notify(relay_competition)

        body = captured.join("\n")
        expect(body).to include("Ion X")
        expect(body).to include("Mihai X")
        expect(body).to include("Andrei X")
        expect(body).to include("(confirmat)")
        expect(body).to include("(plafonat)")
        # Team aggregate should NOT appear — no team name, no team total time.
        expect(body).not_to include("MDA-1")
      end

      it "skips legs whose status is not confirmed/capped" do
        make_leg(name: "Pending", status: Result::PENDING)
        make_leg(name: "Unconfirmed", status: Result::UNCONFIRMED)

        captured = []
        allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

        expect(described_class.notify(relay_competition)).to eq(0)
        expect(captured).to be_empty
      end
    end
  end
end
