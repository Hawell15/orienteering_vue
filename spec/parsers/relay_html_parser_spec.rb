require "rails_helper"

RSpec.describe RelayHtmlParser do
  let!(:club) { Club.find_or_create_by!(id: Club::DEFAULT_CLUB_ID) { |c| c.club_name = "Default" } }
  let!(:no_category) { Category.find_or_create_by!(id: Category::NO_CATEGORY_ID) { |c| c.category_name = "f/c" } }

  # SportOrg encodes relay legs in person bibs as LTTT (L = leg, TTT = team).
  # Team 601 = bibs 1601 / 2601 / 3601; team 602 = bibs 1602 / 2602 / 3602.
  let(:race_data) do
    {
      "data" => {
        "title"             => "Cupa Relay HTML",
        "start_datetime"    => "2026-05-02 11:00:00",
        "description"       => "эстафета",
        "relay_leg_count"   => 3
      },
      "groups" => [
        { "id" => "g1", "name" => "M21 - 2007 г.р и старше" }
      ],
      "organizations" => [
        { "id" => "org-tiras", "name" => "ȘS Tiraspol, Moldova" },
        { "id" => "org-galata", "name" => "CS Galata " }
      ],
      "persons" => [
        { "id" => "p1", "bib" => 1601, "group_id" => "g1", "organization_id" => "org-tiras",  "sex" => 0, "surname" => "Babici",   "name" => "Artiom",   "birth_date" => "2007-05-10" },
        { "id" => "p2", "bib" => 2601, "group_id" => "g1", "organization_id" => "org-tiras",  "sex" => 0, "surname" => "Fomiciov", "name" => "Anatolii", "birth_date" => "1997-04-26" },
        { "id" => "p3", "bib" => 3601, "group_id" => "g1", "organization_id" => "org-tiras",  "sex" => 0, "surname" => "Fomiciov", "name" => "Ivan",     "birth_date" => "1994-01-17" },
        { "id" => "p4", "bib" => 1602, "group_id" => "g1", "organization_id" => "org-galata", "sex" => 0, "surname" => "Ciobanu",  "name" => "Roman",    "birth_date" => "1991-02-15" },
        { "id" => "p5", "bib" => 2602, "group_id" => "g1", "organization_id" => "org-galata", "sex" => 0, "surname" => "Fala",     "name" => "Sergiu",   "birth_date" => "1993-05-27" },
        { "id" => "p6", "bib" => 3602, "group_id" => "g1", "organization_id" => "org-galata", "sex" => 0, "surname" => "Golovei",  "name" => "Andrei",   "birth_date" => "1993-12-12" }
      ],
      "results" => [
        { "person_id" => "p1", "place" => 1, "order" => 1, "result" => "00:40:47", "result_msec" => 2447000, "result_relay_msec" => 2447000, "status" => 1 },
        { "person_id" => "p2", "place" => 1, "order" => 2, "result" => "00:29:57", "result_msec" => 1797000, "result_relay_msec" => 4244000, "status" => 1 },
        { "person_id" => "p3", "place" => 1, "order" => 3, "result" => "00:34:53", "result_msec" => 2093000, "result_relay_msec" => 6337000, "status" => 1 },
        { "person_id" => "p4", "place" => 2, "order" => 1, "result" => "00:38:52", "result_msec" => 2332000, "result_relay_msec" => 2332000, "status" => 1 },
        { "person_id" => "p5", "place" => 2, "order" => 2, "result" => "00:36:02", "result_msec" => 2162000, "result_relay_msec" => 4494000, "status" => 1 },
        { "person_id" => "p6", "place" => 2, "order" => 3, "result" => "00:35:23", "result_msec" => 2123000, "result_relay_msec" => 6617000, "status" => 1 }
      ]
    }
  end

  # `HtmlParser#convert` does:
  #   html.at_css("div#content script").text.sub("\n    var race = ", "").split(";").first
  # — so the script body must start with "\n    var race = " (newline + 4 spaces)
  # and end with ";". Indentation here matters; don't reformat.
  def build_html_file(data)
    file = Tempfile.new([ "test_relay", ".html" ])
    file.write(%(<!doctype html><html><body><div id="content"><script>\n    var race = #{data.to_json};</script></div></body></html>))
    file.rewind
    file.path
  end

  let(:html_path) { build_html_file(race_data) }

  describe "#distance_type" do
    it "honors a classic relay_type override" do
      parser = RelayHtmlParser.new(html_path, relay_type: "classic")
      expect(parser.distance_type(race_data)).to eq("Ștafetă clasică")
    end

    it "honors a sprint relay_type override" do
      parser = RelayHtmlParser.new(html_path, relay_type: "sprint")
      expect(parser.distance_type(race_data)).to eq("Ștafetă sprint")
    end

    it "falls back to relay_leg_count when no override given" do
      parser = RelayHtmlParser.new(html_path)
      classic = race_data.deep_dup.tap { |d| d["data"]["relay_leg_count"] = 3 }
      sprint  = race_data.deep_dup.tap { |d| d["data"]["relay_leg_count"] = 4 }
      expect(parser.distance_type(classic)).to eq("Ștafetă clasică")
      expect(parser.distance_type(sprint)).to eq("Ștafetă sprint")
    end
  end

  describe "#convert" do
    it "creates competition, group, RelayResults and leg Results" do
      result = RelayHtmlParser.new(html_path, relay_type: "classic").convert

      expect(result).to be_a(Competition)
      expect(result.competition_name).to eq("Cupa Relay HTML")
      expect(result.distance_type).to eq("Ștafetă clasică")
      expect(result.date.to_s).to eq("2026-05-02")

      group = Group.find_by(competition: result, group_name: "M21")
      expect(group).to be_present

      relays = RelayResult.where(group: group).order(:place)
      expect(relays.size).to eq(2)
    end

    it "preserves leg order via the `order` field" do
      RelayHtmlParser.new(html_path, relay_type: "classic").convert
      relay = RelayResult.find_by(place: 1)
      legs  = relay.results_id.map { |id| Result.find(id) }
      expect(legs.map { |r| r.membership.runner.runner_name }).to eq(%w[Babici Fomiciov Fomiciov])
    end

    it "uses the cumulative final-leg time for the team total" do
      RelayHtmlParser.new(html_path, relay_type: "classic").convert
      relay = RelayResult.find_by(place: 1)
      expect(relay.time).to eq(6337) # 6_337_000 ms / 1000
    end

    it "joins distinct club names with '/' for the team field" do
      mixed = race_data.deep_dup
      mixed["persons"][2]["organization_id"] = "org-galata" # last leg of team 1 from a different club
      path = build_html_file(mixed)

      RelayHtmlParser.new(path, relay_type: "classic").convert
      relay = RelayResult.find_by(place: 1)
      expect(relay.team.split("/").sort).to eq([ "CS Galata", "ȘS Tiraspol, Moldova" ])
    end

    it "skips teams that don't have all legs status=1 (DNF/DSQ)" do
      data = race_data.deep_dup
      data["results"][1]["status"] = 4 # team 1 leg 2 fails
      path = build_html_file(data)

      RelayHtmlParser.new(path, relay_type: "classic").convert
      group  = Group.find_by(group_name: "M21")
      places = RelayResult.where(group: group).pluck(:place)
      expect(places).to eq([ 2 ])
    end

    it "skips teams that don't have the expected leg count" do
      data = race_data.deep_dup
      data["results"].shift # team 1 now only has 2 legs
      data["persons"].shift # and only 2 persons
      path = build_html_file(data)

      RelayHtmlParser.new(path, relay_type: "classic").convert
      group  = Group.find_by(group_name: "M21")
      places = RelayResult.where(group: group).pluck(:place)
      expect(places).to eq([ 2 ])
    end
  end
end
