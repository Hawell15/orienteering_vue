class TelegramNotifier
  require "net/http"
  require "json"

  CHANNEL  = "@categorii_orientare".freeze
  API_HOST = "https://api.telegram.org".freeze

  MAX_MESSAGE_LENGTH = 4096

  class TokenMissingError < StandardError; end

  def self.notify(message, chat_id: CHANNEL, parse_mode: nil, disable_web_page_preview: true)
    token = bot_token
    raise TokenMissingError, "Telegram bot token not configured" if token.blank?

    body = { chat_id: chat_id, text: message, disable_web_page_preview: disable_web_page_preview }
    body[:parse_mode] = parse_mode if parse_mode

    uri = URI("#{API_HOST}/bot#{token}/sendMessage")
    response = Net::HTTP.post(uri, body.to_json, "Content-Type" => "application/json")

    response.is_a?(Net::HTTPSuccess)
  end

  def self.bot_token
    Rails.application.credentials.dig(:telegram, :bot_token).presence ||
      ENV["TELEGRAM_BOT_TOKEN"]
  end
end
