class TelegramCompetitionNotifier
  STATUS_LABELS = {
    Result::CONFIRMED => "confirmat",
    Result::CAPPED    => "plafonat"
  }.freeze

  def self.notify(competition, host: nil)
    new(competition, host: host).call
  end

  def initialize(competition, host: nil)
    @competition = competition
    @host        = host
    @collector   = CompetitionConfirmedResults.new(competition)
  end

  def call
    messages = build_messages
    return 0 if messages.empty?

    messages.each { |m| TelegramNotifier.notify(m, parse_mode: "HTML") }
    messages.size
  end

  private

  def build_messages
    return [] if @collector.empty?

    header = competition_header

    @collector.by_group.flat_map do |group_name, results|
      chunks_for_group(group_name, results, header)
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

  def chunks_for_group(group_name, results, header)
    group_header = "#{header}\n\n📊 <b>#{escape(group_name)}</b>"
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
    full_name = escape(result.full_name.to_s.strip)
    yob       = result.yob.to_i.positive? ? result.yob : "—"
    club      = escape(result.club_name.presence || "—")
    current   = escape(result.runner_category_name.presence || "f/c")
    new_cat   = escape(result.new_category_name.presence || "f/c")
    status    = STATUS_LABELS.fetch(result.status, result.status)

    "• #{full_name}, #{yob}, #{club}: #{current} → #{new_cat} (#{status})"
  end

  def escape(text)
    ERB::Util.html_escape(text.to_s)
  end
end
