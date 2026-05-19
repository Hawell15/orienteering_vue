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

    group.results.where.not(time: [nil, 0]).each do |result|
      result.update!(ecn_points: get_ecn_points(winner_time, coeficient, result.time))
    end
  end

  private

  def self.get_ecn_points(winner_time, coeficient, time)
    (coeficient * winner_time / time * 100).round(2)
  end
end
