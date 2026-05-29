class TelegramCompetitionNotifier
  REPORTED_STATUSES = [ Result::CONFIRMED, Result::CAPPED ].freeze

  STATUS_LABELS = {
    Result::CONFIRMED => "confirmat",
    Result::CAPPED    => "limitat"
  }.freeze

  def self.notify(competition, host: nil)
    new(competition, host: host).call
  end

  def initialize(competition, host: nil)
    @competition = competition
    @host        = host
  end

  def call
    messages = build_messages
    return 0 if messages.empty?

    messages.each { |m| TelegramNotifier.notify(m, parse_mode: "HTML") }
    messages.size
  end

  private

  def build_messages
    groups = groups_with_reportable_results
    return [] if groups.empty?

    header = competition_header

    groups.flat_map do |group, results|
      chunks_for_group(group, results, header)
    end
  end

  def competition_header
    name_html = if @host
      url = "#{@host.chomp('/')}/competitions/#{@competition.id}"
      %(🏁 <a href="#{escape(url)}">#{escape(@competition.competition_name)}</a>)
    else
      %(🏁 <b>#{escape(@competition.competition_name)}</b>)
    end

    parts = [
      @competition.distance_type,
      @competition.date&.strftime("%d.%m.%Y")
    ].compact.reject(&:blank?)

    parts.empty? ? name_html : "#{name_html}\n#{escape(parts.join(' · '))}"
  end

  def groups_with_reportable_results
    Group
      .where(competition_id: @competition.id)
      .order(:group_name)
      .map { |group| [ group, reportable_results_for(group) ] }
      .reject { |_group, results| results.empty? }
  end

  def reportable_results_for(group)
    group.results
         .joins(:category, membership: [ :runner, :club ])
         .with_runner_category_on_date
         .where(status: REPORTED_STATUSES, parent_result_id: nil)
         .order(:place)
         .select(<<~SQL)
           results.*,
           categories.category_name AS new_category_name,
           runner_actual_category.category_name AS current_category_name,
           runners.runner_name AS runner_name,
           runners.surname AS runner_surname,
           runners.yob AS runner_yob,
           clubs.club_name AS club_name
         SQL
         .to_a
  end

  def chunks_for_group(group, results, header)
    group_header = "#{header}\n\n📊 <b>#{escape(group.group_name)}</b>"
    lines        = results.map { |r| format_result_line(r) }

    chunks    = []
    buffer    = group_header.dup
    separator = "\n"

    lines.each do |line|
      candidate = "#{buffer}#{separator}#{line}"

      if candidate.length > TelegramNotifier::MAX_MESSAGE_LENGTH
        chunks << buffer
        buffer = "#{group_header} (continuare)\n#{line}"
      else
        buffer = candidate
      end
    end

    chunks << buffer
    chunks
  end

  def format_result_line(result)
    full_name = escape("#{result.runner_name} #{result.runner_surname}".strip)
    yob       = result.runner_yob.to_i.positive? ? result.runner_yob : "—"
    club      = escape(result.club_name.presence || "—")
    current   = escape(result.current_category_name.presence || "f/c")
    new_cat   = escape(result.new_category_name.presence || "f/c")
    status    = STATUS_LABELS.fetch(result.status, result.status)

    "• #{full_name}, #{yob}, #{club}: #{current} → #{new_cat} (#{status})"
  end

  def escape(text)
    ERB::Util.html_escape(text.to_s)
  end
end
