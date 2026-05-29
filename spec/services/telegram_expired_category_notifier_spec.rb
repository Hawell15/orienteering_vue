require "rails_helper"

RSpec.describe TelegramExpiredCategoryNotifier do
  # before(:suite) already seeded categories 1..10 with names "Cat1"…"Cat10"; we
  # just need them on hand for the runner associations.
  let!(:cat5) { Category.find(5) }
  let!(:cat6) { Category.find(6) }
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Olimp & Co" } }

  def make_runner(name:, surname:, yob: 2000, category: cat6)
    Runner.create!(club: club, runner_name: name, surname: surname, gender: "M", yob: yob, category: category, best_category: category)
  end

  before { allow(TelegramNotifier).to receive(:notify).and_return(true) }

  describe ".notify" do
    it "returns 0 and sends nothing for an empty change set" do
      expect(TelegramNotifier).not_to receive(:notify)
      expect(described_class.notify([])).to eq(0)
    end

    it "sends a single message for a small change set" do
      runner = make_runner(name: "Ion", surname: "Pop")
      described_class.notify([ { runner: runner, old_category_id: 5, new_category_id: 6 } ])
      expect(TelegramNotifier).to have_received(:notify).once
    end

    it "uses HTML parse mode" do
      runner = make_runner(name: "Ion", surname: "Pop")
      described_class.notify([ { runner: runner, old_category_id: 5, new_category_id: 6 } ])
      expect(TelegramNotifier).to have_received(:notify).with(anything, parse_mode: "HTML")
    end

    it "formats one bullet per runner with runner_name, yob, club and category change" do
      captured = []
      allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

      runner_a = make_runner(name: "Ion", surname: "Pop", yob: 2005)
      runner_b = make_runner(name: "Ana", surname: "Marin", yob: 1999)

      described_class.notify([
        { runner: runner_a, old_category_id: 5, new_category_id: 6 },
        { runner: runner_b, old_category_id: 6, new_category_id: Category::NO_CATEGORY_ID }
      ])

      body = captured.join("\n")
      expect(body).to include("Ion Pop, 2005, Olimp &amp; Co: Cat5 → Cat6")
      expect(body).to include("Ana Marin, 1999, Olimp &amp; Co: Cat6 → Cat10")
    end

    it "renders yob as '—' when zero/unknown" do
      captured = []
      allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

      runner = Runner.create!(club: club, runner_name: "Unk", surname: "Yob", gender: "M", yob: 0, category: cat5, best_category: cat5)
      described_class.notify([ { runner: runner, old_category_id: 5, new_category_id: 6 } ])

      expect(captured.first).to include("Unk Yob, —, Olimp")
    end

    it "splits into multiple chunks once the message would exceed Telegram's limit" do
      stub_const("TelegramNotifier::MAX_MESSAGE_LENGTH", 200)
      captured = []
      allow(TelegramNotifier).to receive(:notify) { |msg, **| captured << msg; true }

      changes = 6.times.map do |i|
        runner = make_runner(name: "Runner#{i}", surname: "X#{i}")
        { runner: runner, old_category_id: 5, new_category_id: 6 }
      end

      sent = described_class.notify(changes)

      expect(sent).to be > 1
      expect(captured.drop(1).any? { |m| m.include?("(continuare)") }).to be true
      expect(captured.all? { |m| m.length <= TelegramNotifier::MAX_MESSAGE_LENGTH }).to be true
    end
  end
end
