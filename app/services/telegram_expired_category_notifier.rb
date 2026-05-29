class TelegramExpiredCategoryNotifier
  def self.notify(changes)
    new(changes).call
  end

  def initialize(changes)
    @changes = changes
  end

  def call
    return 0 if @changes.empty?

    chunks = build_chunks
    chunks.each { |c| TelegramNotifier.notify(c, parse_mode: "HTML") }
    chunks.size
  end

  private

  def build_chunks
    header = "📉 <b>Reducere categorii</b> · #{Date.today.strftime('%d.%m.%Y')}"
    lines  = @changes.map { |c| format_line(c) }

    chunks = []
    buffer = header.dup

    lines.each do |line|
      candidate = "#{buffer}\n#{line}"

      if candidate.length > TelegramNotifier::MAX_MESSAGE_LENGTH
        chunks << buffer
        buffer = "#{header} (continuare)\n#{line}"
      else
        buffer = candidate
      end
    end

    chunks << buffer
    chunks
  end

  def format_line(change)
    runner = change[:runner]
    full_name = escape("#{runner.runner_name} #{runner.surname}".strip)
    yob       = runner.yob.to_i.positive? ? runner.yob : "—"
    club      = escape(runner.club&.club_name.presence || "—")
    old_name  = escape(category_name(change[:old_category_id]))
    new_name  = escape(category_name(change[:new_category_id]))

    "• #{full_name}, #{yob}, #{club}: #{old_name} → #{new_name}"
  end

  def category_name(id)
    category_names[id] || "—"
  end

  def category_names
    @category_names ||= Category.pluck(:id, :category_name).to_h
  end

  def escape(text)
    ERB::Util.html_escape(text.to_s)
  end
end
