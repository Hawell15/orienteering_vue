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
      {
        group_name: group["name"],
        results:    extract_results(json, extract_gender(group["name"].first), group)
      }
    end
  end

  def extract_results(json, gender, group)
    json["persons"].select { |pers| pers["group_id"] == group["id"] }.map do |runner|
      result = json["results"].detect { |res| res["person_id"] == runner["id"] }
      next if result.nil? || !check_result?(result["result"]) || result["place"].to_i < 1 || runner.blank?

      club = json["organizations"].detect { |org| org["id"] == runner["organization_id"] }&.fetch("name")

      {
        place:      result["place"],
        time:       result["result_msec"] / 1000,
        runner:     extract_runner(runner, gender, club),
        membership: club,
        category_id: Category::NO_CATEGORY_ID
      }
    end
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
