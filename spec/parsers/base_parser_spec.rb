require "rails_helper"

RSpec.describe BaseParser do
  let(:parser) { BaseParser.new }

  describe "#convert_time" do
    it "converts mm:ss format" do
      expect(parser.send(:convert_time, "12:34")).to eq(12 * 60 + 34)
    end

    it "converts h:mm:ss format" do
      expect(parser.send(:convert_time, "1:02:03")).to eq(1 * 3600 + 2 * 60 + 3)
    end

    it "converts mm.ss format" do
      expect(parser.send(:convert_time, "10.30")).to eq(10 * 60 + 30)
    end

    it "converts mm,ss format" do
      expect(parser.send(:convert_time, "10,30")).to eq(10 * 60 + 30)
    end

    it "handles mm:ss with leading zero" do
      expect(parser.send(:convert_time, "01:05")).to eq(1 * 60 + 5)
    end
  end

  describe "#extract_gender" do
    it "returns M for masculine variants" do
      %w[m men М м].each do |val|
        expect(parser.send(:extract_gender, val)).to eq("M")
      end
    end

    it "returns W for feminine variants" do
      %w[w women f feminin Ж ж].each do |val|
        expect(parser.send(:extract_gender, val)).to eq("W")
      end
    end

    it "returns nil for unknown" do
      expect(parser.send(:extract_gender, "x")).to be_nil
    end
  end

  describe "#detect_gender" do
    it "returns M for known male names" do
      %w[Nichita Ilia Mircea Nikita Nicola].each do |name|
        expect(parser.send(:detect_gender, name)).to eq("M")
      end
    end

    it "returns W for names ending in a" do
      expect(parser.send(:detect_gender, "Maria")).to eq("W")
      expect(parser.send(:detect_gender, "Elena")).to eq("W")
    end

    it "returns W for Irene" do
      expect(parser.send(:detect_gender, "Irene")).to eq("W")
    end

    it "defaults to M for unknown names not ending in a" do
      expect(parser.send(:detect_gender, "Ion")).to eq("M")
    end
  end

  describe "#add_competition" do
    let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
    let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

    it "creates a competition and groups" do
      hash = {
        competition_name: "Test Comp",
        date: Date.new(2025, 6, 1).as_json,
        distance_type: "Sprint",
        groups: [
          { group_name: "M21", results: [] }
        ]
      }

      expect { parser.add_competition(hash) }.to change(Competition, :count).by(1)
        .and change(Group, :count).by(1)
    end

    it "sets return_result to competition when return_data is competition" do
      parser.return_data = "competition"
      hash = {
        competition_name: "Test",
        date: Date.new(2025, 6, 1).as_json,
        distance_type: "Sprint",
        groups: [ { group_name: "M21", results: [] } ]
      }
      parser.add_competition(hash)
      expect(parser.return_result).to be_a(Competition)
    end
  end

  describe "#add_runners" do
    let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
    let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

    it "creates a runner" do
      hash = { runner_name: "Ion", surname: "Popescu", yob: 2000, gender: "M", club: "Default" }
      expect { parser.add_runners(hash) }.to change(Runner, :count).by(1)
    end

    it "returns nil when hash is nil" do
      expect(parser.add_runners(nil)).to be_nil
    end

    it "uses club_id if provided" do
      hash = { runner_name: "Ion", surname: "Popescu", yob: 2000, gender: "M", club_id: club.id }
      runner = parser.add_runners(hash)
      expect(runner.club_id).to eq(club.id)
    end

    it "sets return_result to runner when return_data is runner" do
      parser.return_data = "runner"
      hash = { runner_name: "Ion", surname: "Popescu", yob: 2000, gender: "M", club: "Default" }
      parser.add_runners(hash)
      expect(parser.return_result).to be_a(Runner)
    end
  end
end
