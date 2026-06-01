class JsonParser < BaseParser
  attr_accessor :hash

  def initialize(path)
    @path          = path
    @hash          = {}
    @return_data   = "competition"
    @return_result = nil
  end

  def convert
    json = JSON.parse(File.read(@path))
    extract_competition_details(json)
    parser(@hash)
    @return_result
  end

  def extract_competition_details(json)
    @hash = {
      competition_name: json["title"],
      date:             Date.strptime(json["date"], "%d.%m.%Y"),
      distance_type:    distance_type(json),
      groups:           extract_groups_details(json["groups"])
    }
  end

  def extract_groups_details(json)
    json.map do |group|
      group_name = Group.normalize_group_name(group["name"])

      {
        group_name: group_name,
        results:    extract_results(group["results"], extract_gender(group_name.first))
      }
    end
  end

  def extract_results(json, gender)
    json.map do |result|
      next if result.blank?

      {
        place:       result["place"],
        time:        convert_time(result["time"]),
        runner:      extract_runner(result, gender),
        membership:  result["club"],
        category_id: Category::NO_CATEGORY_ID
      }
    end
  end

  def extract_runner(result, gender)
    runner_name, surname = result["runner_name"].split(" ", 2)

    {
      runner_name: runner_name,
      surname:     surname,
      yob:         extract_yob(result["date_of_birth"]),
      club:        result["club"],
      gender:      gender
    }.compact
  end

  def extract_yob(string)
    return 0 if string == "Null"

    string.to_date.year
  end

  def distance_type(json)
    json["groups"].first["distance_type"]
  end
end
