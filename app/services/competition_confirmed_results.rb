class CompetitionConfirmedResults
  REPORTED_STATUSES = [ Result::CONFIRMED, Result::CAPPED ].freeze

  attr_reader :competition

  def initialize(competition)
    @competition = competition
  end

  def rows
    @rows ||= load_rows
  end

  def empty?
    rows.empty?
  end

  # [[group_name, [row, row, ...]], ...] — sorted by group_name.
  def by_group
    @by_group ||= rows.group_by(&:group_name).sort_by(&:first)
  end

  # { capped: [...], improved: [...], extended: [...] }
  #
  # - capped:   status == CAPPED — runner achieved a category higher than their
  #             best_category; awaits Ministry confirmation.
  # - improved: status == CONFIRMED — new category strictly better than the
  #             runner's prior on-date category.
  # - extended: status == CONFIRMED — same category as before, validity prolonged.
  def buckets
    @buckets ||= build_buckets
  end

  # parent_result_id (the capped row's id) => achieved category name (from the
  # pending child row).
  def achievement_by_parent_id
    @achievement_by_parent_id ||= load_achievements
  end

  private

  def load_rows
    Result
      .joins(:group, :category, membership: [ :runner, :club ])
      .where("groups.competition_id": @competition.id)
      .where(status: REPORTED_STATUSES)
      .where(parent_result_id: nil)
      .where.not(category_id: Category::NO_CATEGORY_ID)
      .with_runner_category_on_date
      .select(<<~SQL)
        results.*,
        categories.category_name AS new_category_name,
        runner_actual_category.id AS runner_category_id,
        runner_actual_category.category_name AS runner_category_name,
        CONCAT(runners.runner_name, ' ', runners.surname) AS full_name,
        runners.id AS runner_id,
        runners.yob AS yob,
        clubs.id AS club_id,
        clubs.club_name AS club_name,
        groups.group_name AS group_name
      SQL
      .order("groups.group_name ASC, results.place ASC NULLS LAST")
      .to_a
  end

  def build_buckets
    capped   = []
    improved = []
    extended = []

    rows.each do |r|
      if r.status == Result::CAPPED
        capped << r
      elsif r.category_id.to_i < r.runner_category_id.to_i
        improved << r
      elsif r.category_id.to_i == r.runner_category_id.to_i
        extended << r
      end
    end

    { capped: capped, improved: improved, extended: extended }
  end

  def load_achievements
    capped_ids = rows.select { |r| r.status == Result::CAPPED }.map(&:id)
    return {} if capped_ids.empty?

    Result.where(parent_result_id: capped_ids)
          .joins(:category)
          .pluck(:parent_result_id, "categories.category_name")
          .to_h
  end
end
