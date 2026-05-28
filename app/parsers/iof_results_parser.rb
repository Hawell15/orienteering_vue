class IofResultsParser < BaseParser
  require "net/http"

  attr_accessor :hash

  def initialize
    @hash          = {}
    @return_data   = nil
    @return_result = nil
  end

  def convert
    data = get_data
    extract_competition_details(data)

    @hash.each { |comp| parser(comp) }
  end

  def extract_competition_details(json)
    @hash = json.map { |js| js.slice("raceDate", "raceName", "raceId", "raceFormat") }.uniq.map do |competition|
      date = competition["raceDate"].to_date
      {
        competition_name: competition["raceName"],
        date:             date.as_json,
        distance_type:    competition["raceFormat"],
        wre_id:           competition["raceId"],
        groups:           extract_groups_details(json.select { |js| js["raceId"] == competition["raceId"] }, date)
      }
    end.compact
  end

  def extract_groups_details(json, date)
    json.pluck("gender").uniq.map do |group|
      {
        group_name:  Group.normalize_group_name("#{group.first}21E"),
        results:  extract_results(json.select { |js| js["gender"] == group }, date)
      }
    end
  end

  def extract_results(json, date)
    json.map do |result|
      next if result["rank"].to_i.zero?

      {
        place:       result["rank"],
        time:        convert_time(result["result"]),
        wre_points:  result["points"].to_i,
        runner_id:   result["runner_id"],
        category_id: self.class.get_wre_category(result["points"].to_i),
        membership:  "Moldova WRE",
        date:         date.as_json
      }
    end.compact
  end

  def get_data
    runners_with_wre_id = Runner.where.not(wre_id: nil).select(:id, :wre_id, :gender)

    runners_with_wre_id.map do |runner|
      get_runner_results(runner)
    end.flatten
  end

  def get_runner_results(runner)
    [ "F", "FS" ].map do |distance_type|
      json = request_runner_results(runner.wre_id, distance_type)
      json.each do |hash|
        hash["gender"]        = runner.gender
        hash["runner_wre_id"] = runner.wre_id
        hash["runner_id"]     = runner.id
      end
    end.flatten
  end

  def request_runner_results(wre_id, distance_type)
    JSON.parse(Net::HTTP.get(URI("https://ranking.orienteering.org/api/person/#{wre_id}/results/#{distance_type}")))
  end

  def self.get_wre_category(points)
    case points
    when 700..900   then 4
    when 901..1050  then 3
    when 1051..1250 then 2
    when 1251..1500 then 1
    else 10
    end
  end
end
