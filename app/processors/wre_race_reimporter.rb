class WreRaceReimporter
  require "net/http"

  RACE_API_URL_TEMPLATE  = "https://ranking.orienteering.org/api/race/%d".freeze
  GROUP_NAME_BY_API_NAME = { "Men" => "M21E", "Women" => "W21E" }.freeze
  EXCLUDED_RANKS         = [ 0, 99_999 ].freeze

  def initialize(competition)
    @competition = competition
  end

  def call
    return 0 unless @competition.wre_id

    updated = 0

    fetch_race_data.each do |group_data|
      group = find_group(group_data["group"])
      next unless group

      group_data["results"].each do |entry|
        updated += 1 if reimport_entry(group, entry)
      end
    end

    updated
  end

  private

  def fetch_race_data
    JSON.parse(Net::HTTP.get(URI(RACE_API_URL_TEMPLATE % @competition.wre_id)))
  end

  def find_group(api_group_name)
    name = GROUP_NAME_BY_API_NAME[api_group_name]
    return unless name

    @competition.groups.find_by(group_name: Group.normalize_group_name(name))
  end

  def reimport_entry(group, entry)
    return false if EXCLUDED_RANKS.include?(entry["rank"].to_i)

    runner = Runner.find_by(wre_id: entry["iofid"])
    return false unless runner

    result = group.results.joins(:membership).find_by("memberships.runner_id": runner.id)
    return false unless result

    new_points = entry["points"].to_i
    return false if result.wre_points == new_points

    result.update!(
      wre_points:  new_points,
      category_id: IofResultsParser.get_wre_category(new_points)
    )
    true
  end
end
