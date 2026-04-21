class JsonParser < BaseParser
  attr_accessor :file, :hash

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
    date = json["date"].to_date
    @hash = {
      competition_name: json["title"],
      date:             date.as_json,
      distance_type:    json["groups"].first["distance_type"],
      groups:           extract_groups_details(json["groups"], date)
    }
  end

  def extract_groups_details(json, date)
    json.map do |group|
      {
        group_name: group["name"],
        clasa:      convert_group_class(group["distance_class"]),
        results:    extract_results(group["results"], extract_gender(group["name"].first), date)
      }
    end
  end

  def extract_results(json, gender, date)
    json.map do |result|
      next if result.blank?

      {
        place:       result["place"],
        time:        convert_time(result["time"]),
        runner:      extract_runner(result, gender, date),
        membership:  result["club"],
        category_id: Category::NO_CATEGORY_ID
      }
    end
  end

  def extract_runner(result, gender, date)
    runner_name, surname = result["runner_name"].split(" ", 2)

    {
      runner_name: runner_name,
      surname:     surname,
      yob:         extract_yob(result["date_of_birth"]),
      gender:      gender
    }.compact
  end

  def extract_yob(string)
    return 0 if string == "Null"

    string.to_date.year
  end
end
