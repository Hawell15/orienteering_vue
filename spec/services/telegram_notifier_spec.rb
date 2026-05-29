require "rails_helper"

RSpec.describe TelegramNotifier do
  describe ".notify" do
    let(:fake_response) { instance_double(Net::HTTPSuccess) }

    before do
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(described_class).to receive(:bot_token).and_return("fake-token")
    end

    it "posts to the Telegram sendMessage endpoint" do
      expect(Net::HTTP).to receive(:post) do |uri, body, headers|
        expect(uri.to_s).to eq("https://api.telegram.org/botfake-token/sendMessage")
        parsed = JSON.parse(body)
        expect(parsed).to include("chat_id" => described_class::CHANNEL, "text" => "hello")
        expect(parsed).not_to have_key("parse_mode")
        expect(headers).to eq("Content-Type" => "application/json")
        fake_response
      end

      expect(described_class.notify("hello")).to be true
    end

    it "passes parse_mode when provided" do
      expect(Net::HTTP).to receive(:post) do |_uri, body, _headers|
        expect(JSON.parse(body)["parse_mode"]).to eq("HTML")
        fake_response
      end

      described_class.notify("<b>hi</b>", parse_mode: "HTML")
    end

    it "allows overriding chat_id" do
      expect(Net::HTTP).to receive(:post) do |_uri, body, _headers|
        expect(JSON.parse(body)["chat_id"]).to eq("@other_channel")
        fake_response
      end

      described_class.notify("hi", chat_id: "@other_channel")
    end

    it "returns false on non-success response" do
      failure = instance_double(Net::HTTPBadRequest)
      allow(failure).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(Net::HTTP).to receive(:post).and_return(failure)

      expect(described_class.notify("hi")).to be false
    end

    it "raises TokenMissingError when no token is configured" do
      allow(described_class).to receive(:bot_token).and_return(nil)
      expect { described_class.notify("hi") }.to raise_error(TelegramNotifier::TokenMissingError)
    end
  end

  describe ".bot_token" do
    around do |example|
      original = ENV["TELEGRAM_BOT_TOKEN"]
      ENV["TELEGRAM_BOT_TOKEN"] = nil
      example.run
      ENV["TELEGRAM_BOT_TOKEN"] = original
    end

    it "prefers Rails credentials when present" do
      allow(Rails.application.credentials).to receive(:dig).with(:telegram, :bot_token).and_return("creds-token")
      ENV["TELEGRAM_BOT_TOKEN"] = "env-token"

      expect(described_class.bot_token).to eq("creds-token")
    end

    it "falls back to ENV when credentials missing" do
      allow(Rails.application.credentials).to receive(:dig).with(:telegram, :bot_token).and_return(nil)
      ENV["TELEGRAM_BOT_TOKEN"] = "env-token"

      expect(described_class.bot_token).to eq("env-token")
    end

    it "returns nil when neither is set" do
      allow(Rails.application.credentials).to receive(:dig).with(:telegram, :bot_token).and_return(nil)
      ENV["TELEGRAM_BOT_TOKEN"] = nil

      expect(described_class.bot_token).to be_nil
    end
  end
end
