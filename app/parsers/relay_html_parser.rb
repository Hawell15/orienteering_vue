class RelayHtmlParser < HtmlParser
  def initialize(path, relay_type: nil)
    super(path)
    @relay_type = relay_type
  end

  def results_count(group)
    group.competition.distance_type == "Ștafetă clasică" ? 3 : 4
  end

  def extract_groups_details(json)
    json["groups"]
      .reject { |g| g["name"][/complimentare/i] }
      .map do |group|
        group_name = Group.normalize_group_name(group["name"].split.first)
        {
          group_name: group_name,
          results:    extract_relay_results(json, group)
        }
      end
  end

  def extract_relay_results(json, group)
    persons_in_group = json["persons"].select { |p| p["group_id"] == group["id"] }
    person_by_id     = persons_in_group.index_by { |p| p["id"] }
    group_results    = json["results"].select { |r| person_by_id.key?(r["person_id"]) }

    group_results
      .reject { |r| r["status"].to_i != 1 || r["place"].to_i <= 0 }
      .group_by { |r| person_by_id[r["person_id"]]["bib"].to_i % 1000 }
      .filter_map { |team_num, rows| build_team(team_num, rows, person_by_id, json["organizations"]) }
  end

  def build_team(team_num, rows, person_by_id, organizations)
    rows       = rows.sort_by { |r| r["order"].to_i }
    total_msec = rows.last["result_relay_msec"] || rows.sum { |r| r["result_msec"].to_i }
    clubs      = rows.map { |r| club_name_for(person_by_id[r["person_id"]], organizations) }
                     .reject(&:blank?).uniq

    {
      place: rows.first["place"].to_i,
      time:  total_msec / 1000,
      team:  clubs.join("/").presence || "Team #{team_num}",
      legs:  rows.map { |r| build_leg(person_by_id[r["person_id"]], r, organizations) }
    }
  end

  def distance_type(json)
    return "Ștafetă sprint"  if @relay_type == "sprint"
    return "Ștafetă clasică" if @relay_type == "classic"

    json.dig("data", "relay_leg_count").to_i == 4 ? "Ștafetă sprint" : "Ștafetă clasică"
  end

  def add_results(hash, group)
    return unless hash

    hash.each do |relay_result|
      next if relay_result[:legs].size != results_count(group)

      RelayResult.create!(
        place:       relay_result[:place],
        time:        relay_result[:time],
        team:        relay_result[:team],
        category_id: Category::NO_CATEGORY_ID,
        group_id:    group.id,
        results_id:  relay_result[:legs].map { |leg| add_result(leg, group) }
      )
    end
  end
end
