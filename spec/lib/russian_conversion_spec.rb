require "rails_helper"

RSpec.describe RussianConversion do
  describe ".contains_cyrillic?" do
    it "returns true for Cyrillic strings" do
      expect(RussianConversion.contains_cyrillic?("Иван")).to be true
    end

    it "returns false for Latin strings" do
      expect(RussianConversion.contains_cyrillic?("Ivan")).to be false
    end

    it "returns true for mixed strings" do
      expect(RussianConversion.contains_cyrillic?("Ivan Иванов")).to be true
    end

    it "returns false for empty strings" do
      expect(RussianConversion.contains_cyrillic?("")).to be false
    end
  end

  describe ".convert_from_russian" do
    it "returns Latin strings unchanged" do
      expect(RussianConversion.convert_from_russian("ivan")).to eq("ivan")
    end

    it "converts basic Cyrillic vowels" do
      expect(RussianConversion.convert_from_russian("а")).to eq("a")
      expect(RussianConversion.convert_from_russian("е")).to eq("e")
      expect(RussianConversion.convert_from_russian("и")).to eq("i")
      expect(RussianConversion.convert_from_russian("о")).to eq("o")
      expect(RussianConversion.convert_from_russian("у")).to eq("u")
    end

    it "converts basic Cyrillic consonants" do
      expect(RussianConversion.convert_from_russian("б")).to eq("b")
      expect(RussianConversion.convert_from_russian("в")).to eq("v")
      expect(RussianConversion.convert_from_russian("г")).to eq("g")
      expect(RussianConversion.convert_from_russian("д")).to eq("d")
      expect(RussianConversion.convert_from_russian("м")).to eq("m")
      expect(RussianConversion.convert_from_russian("н")).to eq("n")
      expect(RussianConversion.convert_from_russian("п")).to eq("p")
      expect(RussianConversion.convert_from_russian("р")).to eq("r")
      expect(RussianConversion.convert_from_russian("с")).to eq("s")
      expect(RussianConversion.convert_from_russian("т")).to eq("t")
      expect(RussianConversion.convert_from_russian("ф")).to eq("f")
    end

    it "converts multi-character mappings" do
      expect(RussianConversion.convert_from_russian("ё")).to eq("io")
      expect(RussianConversion.convert_from_russian("ю")).to eq("iu")
      expect(RussianConversion.convert_from_russian("я")).to eq("ia")
    end

    it "converts special digraph replacements before single-char mapping" do
      # ья -> ia
      expect(RussianConversion.convert_from_russian("ья")).to eq("ia")
      # ия -> ia
      expect(RussianConversion.convert_from_russian("ия")).to eq("ia")
      # кс -> x
      expect(RussianConversion.convert_from_russian("кс")).to eq("x")
    end

    it "converts ки -> chi and ке -> che" do
      expect(RussianConversion.convert_from_russian("ки")).to eq("chi")
      expect(RussianConversion.convert_from_russian("ке")).to eq("che")
    end

    it "converts че -> ce" do
      expect(RussianConversion.convert_from_russian("че")).to eq("ce")
    end

    it "converts ги -> ghi and ге -> ghe" do
      expect(RussianConversion.convert_from_russian("ги")).to eq("ghi")
      expect(RussianConversion.convert_from_russian("ге")).to eq("ghe")
    end

    it "converts Romanian-specific characters" do
      expect(RussianConversion.convert_from_russian("ц")).to eq("ț")
      expect(RussianConversion.convert_from_russian("ч")).to eq("ci")
      expect(RussianConversion.convert_from_russian("ш")).to eq("ș")
      expect(RussianConversion.convert_from_russian("щ")).to eq("ș")
    end

    it "converts full Cyrillic names" do
      result = RussianConversion.convert_from_russian("иван")
      expect(result).to eq("ivan")
    end

    it "converts a name with special digraphs" do
      # Алексей -> uses кс -> x
      result = RussianConversion.convert_from_russian("алексей")
      expect(result).to include("x")
    end

    it "handles ъ, ы, ь, э conversions" do
      expect(RussianConversion.convert_from_russian("ъ")).to eq("i")
      expect(RussianConversion.convert_from_russian("ы")).to eq("î")
      expect(RussianConversion.convert_from_russian("ь")).to eq("i")
      expect(RussianConversion.convert_from_russian("э")).to eq("ă")
    end

    it "converts ж and з" do
      expect(RussianConversion.convert_from_russian("ж")).to eq("j")
      expect(RussianConversion.convert_from_russian("з")).to eq("z")
    end

    it "converts й" do
      expect(RussianConversion.convert_from_russian("й")).to eq("i")
    end

    it "converts х" do
      expect(RussianConversion.convert_from_russian("х")).to eq("h")
    end

    it "converts к to c (single char, not part of digraph)" do
      expect(RussianConversion.convert_from_russian("к")).to eq("c")
    end

    it "preserves non-Cyrillic characters in mixed strings" do
      result = RussianConversion.convert_from_russian("test123")
      expect(result).to eq("test123")
    end
  end
end
