class RelayGroupCategoriesProcessor < GroupCategoriesProcessor
  # Top-N teams whose legs contribute their runners' category points to the
  RANG_TOP_TEAMS = {
    "Ștafetă sprint"  => 3,
    "Ștafetă clasică" => 4
  }.freeze

  def main_results
    @main_results ||= @group.relay_results.order(:place)
  end

  def winner_time
    @winner_time ||= main_results.first&.time
  end

  # The leg `Result` rows of the top-N teams. The parent's `get_group_rang`
  # iterates these and sums each runner's `category_on_date(comp.date).points`.
  def rang_results
    Result
      .where(id: main_results.first(rang_top_teams).flat_map(&:results_id))
      .includes(membership: :runner)
  end

  def update_result_category(relay, category_id)
    relay.update!(category_id: category_id) if relay.category_id != category_id

    Result.where(id: relay.results_id).includes(membership: :runner).find_each do |leg|
      ResultProcessor
        .new({ category_id: category_id, runner_id: leg.runner.id }, leg)
        .update_result
    end

    category_id
  end

  def set_junior_category?(relay)
    competition_date = @group.competition.date
    Result.where(id: relay.results_id).includes(membership: :runner).all? do |leg|
      leg.runner.junior_runner?(competition_date)
    end
  end

  def min_results_size
    2
  end

  private

  def rang_top_teams
    RANG_TOP_TEAMS.fetch(@group.competition.distance_type, 4)
  end
end
