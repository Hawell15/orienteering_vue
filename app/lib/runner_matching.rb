module RunnerMatching
  THRESHOLD = 0.8
  INVALID_RUNNER_ID = 99_999_999

  def self.get_runner_by_matching(options)
    runners = filter_runners_by_options(options)
                .where.not(id: INVALID_RUNNER_ID)

    name     = options[:runner_name].downcase
    surname  = options[:surname].downcase

    # 1. Fast exact-ish match
    soundex_match = runners.find { |r| by_soundex?(r, name, surname) }
    return soundex_match if soundex_match

    # 2. Fuzzy match
    runners
      .filter_map { |r| by_levenshtein(r, name, surname) }
      .min_by(&:first)
      &.last
  end

  private

  def self.filter_runners_by_options(options)
    runners = Runner.where(gender: options[:gender])

    yob = options[:yob]

    unless yob.zero?
      runners = runners.where(yob: (yob - 1)..(yob + 1))
                       .or(runners.where(yob: 0))
    end

    runners
  end

  def self.by_soundex?(runner, name, surname)
    Text::Soundex.soundex(runner.runner_name) == Text::Soundex.soundex(name) &&
      Text::Soundex.soundex(runner.surname) == Text::Soundex.soundex(surname)
  end

  def self.by_levenshtein(runner, name, surname)
    runner_name    = runner.runner_name.downcase
    runner_surname = runner.surname.downcase

    name_dist    = normalized_distance(runner_name, name)
    surname_dist = normalized_distance(runner_surname, surname)

    avg_dist = (name_dist + surname_dist) / 2.0
    similarity = 1 - avg_dist

    return unless similarity >= THRESHOLD

    [ avg_dist, runner ]
  end

  def self.normalized_distance(a, b)
    max_len = [ a.length, b.length ].max
    return 1.0 if max_len.zero?

    Text::Levenshtein.distance(a, b) / max_len.to_f
  end
end
