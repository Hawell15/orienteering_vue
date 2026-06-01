class RelayJsonParser < JsonParser
  def initialize(path, relay_type: "classic")
    super(path)
    @relay_type = relay_type
  end

  def results_count(group)
    group.competition.distance_type == "Ștafetă clasică" ? 3 : 4
  end

  def extract_groups_details(json)
    json.reject { |group| group["name"][/complimentare/i] || group["distance_type"][/заданка/i] }.reject { |g| g["results"].all?(&:blank?) }.map do |group|
      {
        group_name: Group.normalize_group_name(group["name"]),
        results:    extract_relay_results(group["results"], extract_gender(group["name"].first))
      }
    end
  end

  def extract_relay_results(json, gender)
    json.reject { |row| row["runner_name"].blank? || row["place"].to_i.zero? }
      .group_by { |row| row["place"].to_i }.map do |place, results|
        {
          place: place,
          time:  results.map { |res| convert_time(res["time"]) }.sum,
          team:  results.map { |res| res["club"] }.uniq.join("/"),
          legs:  extract_results(results, gender)
        }
    end
  end

  def distance_type(_json)
    @relay_type == "sprint" ? "Ștafetă sprint" : "Ștafetă clasică"
  end

  def add_results(hash, group)
    return unless hash

    hash.each do |relay_result|
      next if relay_result[:legs].size != results_count(group)

      RelayResult.create!(
        place: relay_result[:place],
        time:  relay_result[:time],
        team:  relay_result[:team],
        category_id: Category::NO_CATEGORY_ID,
        group_id:  group.id,
        results_id: relay_result[:legs].map { |leg| add_result(leg, group) }
      )
    end
  end
end
