# Wipes a year's processing artifacts and replays every competition of that
# year in chronological order, simulating category expiry as of each
# competition date. Manual (NoGroup) results — e.g. ministry title
# confirmations — are never touched; their runners' caches are refreshed at
# the right point of the timeline so they feed rang computations and the
# best-category ratchet exactly as they did in real time.
class YearReprocessor
  SPECIAL_GROUP_IDS = [
    Group::REDUCTION_CATEGORY_GROUP_ID,
    Group::THREE_RESULTS_GROUP_ID,
    Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID
  ].freeze

  # Reduction chains within one window are bounded by category validity
  # periods (2+ years); this is a runaway guard, not an expected depth.
  MAX_EXPIRY_PASSES = 5

  def initialize(year, io: $stdout)
    @year = year
    @from = Date.new(year, 1, 1)
    @io   = io
  end

  def call
    reset!
    replay!
    finalize!
  end

  private

  def competitions
    @competitions ||= Competition.where(date: @from..@from.end_of_year).order(:date, :id).to_a
  end

  def reset!
    ActiveRecord::Base.transaction do
      @manual_achievements = collect_manual_achievements

      special = Result.where(group_id: SPECIAL_GROUP_IDS, date: @from..)
      log "reset: deleting #{special.count} reduction/three-results/pending-title results dated from #{@from}"
      special.destroy_all

      comp_ids = competitions.map(&:id)
      scope    = Result.joins(:group).where(groups: { competition_id: comp_ids })
      log "reset: setting #{scope.count} results of #{comp_ids.size} competitions to unconfirmed/no-category"
      scope.update_all(category_id: Category::NO_CATEGORY_ID, status: Result::UNCONFIRMED)
      RelayResult.joins(:group).where(groups: { competition_id: comp_ids }).update_all(category_id: Category::NO_CATEGORY_ID)

      rollback_runner_caches!
    end
  end

  # best_category_id is a one-way ratchet (update_runner_category takes the
  # min), so it must be rebuilt from pre-year confirmed results before the
  # replay re-earns it; the capping logic reads it.
  def rollback_runner_caches!
    log "reset: rolling back runner caches to the #{@from} state"

    ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql([ <<~SQL, { no_cat: Category::NO_CATEGORY_ID, from: @from } ]))
      UPDATE runners SET best_category_id = COALESCE((
        SELECT MIN(r.category_id)
        FROM results r
        JOIN memberships m ON m.id = r.membership_id
        WHERE m.runner_id = runners.id
          AND r.status = 'confirmed'
          AND r.date < :from
          AND r.category_id <> :no_cat
      ), :no_cat)
    SQL

    Runner.find_each { |runner| runner.update_runner_category(@from) }
  end

  def replay!
    checkpoint = @from

    competitions.each do |competition|
      refresh_manual_result_runners!(checkpoint, competition.date)
      run_expiry_checks!(competition.date)
      process_competition!(competition)
      reprocess_no_category_results!(competition)
      reapply_manual_achievements!(competition)
      refresh_competition_runners!(competition)

      checkpoint = competition.date
      log "replayed: #{competition.date}  #{competition.competition_name} (id=#{competition.id})"
    end
  end

  # A confirmed manual result entered on date D updates its runner's cache the
  # moment it is entered in real time; replaying the window [from, to) makes
  # the cache (including the best-category ratchet) reflect it before the next
  # competition, exactly as it did then.
  def refresh_manual_result_runners!(from, to)
    runner_ids = Result.where(group_id: Group::NO_GROUP_ID, status: Result::CONFIRMED, date: from...to)
                       .joins(:membership).distinct.pluck("memberships.runner_id")

    Runner.where(id: runner_ids).find_each { |runner| runner.update_runner_category(to) }
  end

  def run_expiry_checks!(date)
    MAX_EXPIRY_PASSES.times do
      break unless Runner.where("category_valid < ?", date).exists?

      ExpiredCategoryJob.perform_now(date, notify: false)
    end
  end

  def process_competition!(competition)
    return process_wre_competition!(competition) if competition.wre_id.present?

    processor_class = competition.relay? ? RelayGroupCategoriesProcessor : GroupCategoriesProcessor

    competition.groups.order(:id).each do |group|
      scope = competition.relay? ? group.relay_results : group.results
      next if scope.blank?

      processor_class.new(group).get_rang_and_categories
    end
  end

  # Title-achievement children are the trace of manual category assignments
  # made by admins (e.g. for international performances) — the replay cannot
  # recompute those from times, so remember them before the wipe...
  def collect_manual_achievements
    Result.where(group_id: Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID, date: @from..)
          .where.not(parent_result_id: nil)
          .joins("JOIN results parents ON parents.id = results.parent_result_id")
          .joins("JOIN groups parent_groups ON parent_groups.id = parents.group_id")
          .pluck("parent_groups.competition_id", "results.parent_result_id", "results.category_id")
          .group_by(&:first)
  end

  # ...and re-apply each to its parent right after the parent's competition is
  # replayed, exactly like the original admin edit (the categorizer re-caps it
  # and re-creates the pending title child).
  def reapply_manual_achievements!(competition)
    (@manual_achievements[competition.id] || []).each do |(_, parent_id, category_id)|
      parent = Result.find_by(id: parent_id)
      next unless parent

      ResultProcessor.new({ category_id: category_id, runner_id: parent.runner.id }, parent).update_result
      log "re-applied manual category #{category_id} to result #{parent_id}"
    end
  end

  # Competitions with a wre_id don't use rang/time thresholds: each result's
  # category comes from its WRE points — the same rule the IOF import and
  # WreRaceReimporter apply — and the group rang stays unset.
  def process_wre_competition!(competition)
    competition.groups.each do |group|
      group.update!(rang: nil) if group.rang.present?

      group.results.includes(membership: :runner).each do |result|
        category_id = IofResultsParser.get_wre_category(result.wre_points.to_i)
        ResultProcessor.new({ category_id: category_id, runner_id: result.runner.id }, result).update_result
      end
    end
  end

  # The group processor only saves results whose category changed, so results
  # that stay at NO_CATEGORY never re-enter ResultCategorizer — losing the
  # three-results junior promotion originally created when the result was
  # first imported. Force the categorizer through them once per competition.
  def reprocess_no_category_results!(competition)
    Result.joins(:group)
          .where(groups: { competition_id: competition.id }, category_id: Category::NO_CATEGORY_ID)
          .find_each do |result|
      result.category_id_will_change!
      result.save!
    end
  end

  # ResultCategorizer's after_save refreshes runner caches as of Date.today;
  # during a retroactive replay the caches must track the simulated timeline
  # instead, otherwise later expiry checks read post-expiry state and skip
  # reductions. Re-pin every participant's cache to the competition date.
  def refresh_competition_runners!(competition)
    runner_ids = Result.joins(:group, :membership)
                       .where(groups: { competition_id: competition.id })
                       .distinct.pluck("memberships.runner_id")

    Runner.where(id: runner_ids).find_each { |runner| runner.update_runner_category(competition.date + 1.day) }
  end

  def finalize!
    checkpoint = competitions.last&.date || @from
    refresh_manual_result_runners!(checkpoint, Date.today + 1.day)
    run_expiry_checks!(Date.today)
    log "finalize: expiry checks caught up to #{Date.today}"
  end

  def log(message)
    @io.puts("[YearReprocessor #{@year}] #{message}")
  end
end
