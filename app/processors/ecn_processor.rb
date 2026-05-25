class EcnProcessor
  def self.competition_processor(competition)
    competition.groups.each do |group|
      group_processor(group)
    end
  end

  def self.group_processor(group)
    coeficient = group.ecn_coeficient
    return if coeficient.zero?

    winner = group.results.order(:place).first
    return if winner.nil? || winner.time.nil? || winner.time.zero?

    winner_time = winner.time

    group.results.where.not(time: [ nil, 0 ]).each do |result|
      result.update!(ecn_points: get_ecn_points(winner_time, coeficient, result.time))
    end
  end

  def self.limit_number(date)
    from_date = date.to_date - 1.year
    [ Competition.where(ecn: true).where("competitions.date >= ?", from_date).count - 4, 1 ].max
  end

  def self.runner_results(runner, date)
    from_date = date.to_date - 1.year
    limit = limit_number(date)

    results = runner.results
                    .where("ecn_points > 0")
                    .where(date: from_date..date.to_date)
                    .includes(group: :competition)

    cutoff = results.sort_by { |r| -r.ecn_points }[limit - 1]&.ecn_points || 0

    {
      results: results.sort_by { |r| r.date }.reverse,
      min_limit_points: cutoff,
      limit_number: limit
    }
  end

  def self.ranking(gender, date)
    from_date = date.to_date - 1.year
    limit = limit_number(date)

    subquery = Result
                 .joins(:membership)
                 .select("results.id, results.ecn_points, results.date, memberships.runner_id,
                          ROW_NUMBER() OVER (PARTITION BY memberships.runner_id ORDER BY results.ecn_points DESC) AS rn")
                 .where("results.ecn_points > 0")
                 .where("results.date >= ?", from_date)

    Runner.where(gender: gender)
          .joins("JOIN (#{subquery.to_sql}) AS best_results ON best_results.runner_id = runners.id AND best_results.rn <= #{limit}")
          .group("runners.id")
          .select(<<~SQL)
            runners.id,
            runners.runner_name,
            runners.surname,
            runners.yob,
            runners.club_id,
            runners.gender,
            SUM(best_results.ecn_points) AS total_points,
            COUNT(best_results.ecn_points) AS ecn_results_count,
            RANK() OVER (ORDER BY SUM(best_results.ecn_points) DESC) AS place
          SQL
          .order("total_points DESC")
  end

  private

  def self.get_ecn_points(winner_time, coeficient, time)
    (coeficient * winner_time / time * 100).round(2)
  end
end
