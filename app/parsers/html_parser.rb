class HtmlParser < BaseParser
  attr_accessor :hash

  def initialize(path)
    @path          = path
    @hash          = {}
    @return_data   = "competition"
    @return_result = nil
  end

  def convert
    html = Nokogiri::HTML(File.read(@path))
    json = JSON.parse(html.at_css("div#content script").text.sub("\n    var race = ", "").split("\;").first)

    extract_competition_details(json)

    parser(@hash)
    @return_result
  end

  def extract_competition_details(json)
    @hash = {
      competition_name: json.dig("data", "title"),
      date:             json.dig("data", "start_datetime").to_date.as_json,
      distance_type:    distance_type(json),
      groups:           extract_groups_details(json)
    }
  end

  def extract_groups_details(json)
    json["groups"].map do |group|
      group_name = Group.normalize_group_name(group["name"])

      {
        group_name: group_name,
        results:    extract_results(json, group)
      }
    end
  end

  def extract_results(json, group)
    json["persons"]
      .select { |person| person["group_id"] == group["id"] }
      .filter_map do |person|
        result = json["results"].detect { |r| r["person_id"] == person["id"] }
        next unless result && check_result?(result["result"]) && result["place"].to_i.positive?

        build_leg(person, result, json["organizations"])
      end
  end

  def build_leg(person, result, organizations)
    gender = person["sex"].to_i.zero? ? "M" : "W"
    club   = club_name_for(person, organizations)

    {
      place:       result["place"],
      time:        result["result_msec"].to_i / 1000,
      runner:      extract_runner(person, gender, club),
      membership:  club,
      category_id: Category::NO_CATEGORY_ID
    }
  end

  def club_name_for(person, organizations)
    organizations.find { |o| o["id"] == person["organization_id"] }&.fetch("name")&.strip
  end

  def extract_runner(runner, gender, club)
    {
      runner_name: runner["surname"],
      surname:     runner["name"],
      yob:         extract_yob(runner["birth_date"]),
      gender:      gender,
      club:        club
    }.compact
  end

  # NOTE: will be rewritten for relay
  def check_result?(result)
    true
  end

  def distance_type(json)
    json.dig("data", "description").strip
  end

  def extract_yob(string)
    return 0 unless string

    string.to_date.year
  end
end
