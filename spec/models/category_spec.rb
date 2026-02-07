require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:runners) }
    it { is_expected.to have_many(:results) }
  end

  describe ".sorting" do
    let!(:cat1) { Category.create!(category_name: "A", points: 10) }
    let!(:cat2) { Category.create!(category_name: "B", points: 20) }

    it "sorts by allowed column asc" do
      expect(Category.sorting("points", "asc")).to eq([ cat1, cat2 ])
    end

    it "sorts by allowed column desc" do
      expect(Category.sorting("points", "desc")).to eq([ cat2, cat1 ])
    end

    it "falls back to id for invalid column" do
      expect(Category.sorting("hack", "asc")).to eq(Category.order("id asc"))
    end

    it "falls back to asc for invalid direction" do
      expect(Category.sorting("points", "hack")).to eq([ cat1, cat2 ])
    end
  end

  describe ".search" do
    let!(:cat1) { Category.create!(category_name: "Junior", full_name: "Junior category") }
    let!(:cat2) { Category.create!(category_name: "Senior", full_name: "Senior category") }

    it "finds by category_name (case-insensitive)" do
      expect(Category.search("jun")).to include(cat1)
    end

    it "finds by full_name (case-insensitive)" do
      expect(Category.search("senior")).to include(cat2)
    end

    it "returns empty relation when no match" do
      expect(Category.search("zzz")).to be_empty
    end
  end

  describe ".age" do
    let!(:senior) { Category.create!(id: 1, category_name: "Senior") }
    let!(:junior) { Category.create!(id: 7, category_name: "Junior") }

    it "returns senior categories" do
      expect(Category.age("senior")).to include(senior)
      expect(Category.age("senior")).not_to include(junior)
    end

    it "returns junior categories" do
      expect(Category.age("junior")).to include(junior)
      expect(Category.age("junior")).not_to include(senior)
    end

    it "returns all for unknown value" do
      expect(Category.age("unknown")).to match_array(Category.all)
    end
  end

  describe ".points" do
    let!(:low)  { Category.create!(points: 5) }
    let!(:high) { Category.create!(points: 50) }

    it "filters by points range" do
      expect(Category.points(1, 10)).to include(low)
      expect(Category.points(1, 10)).not_to include(high)
    end
  end

  describe ".validaty_period" do
    let!(:short) { Category.create!(validaty_period: 6) }
    let!(:long)  { Category.create!(validaty_period: 24) }

    it "filters by validaty_period range" do
      expect(Category.validaty_period(1, 12)).to include(short)
      expect(Category.validaty_period(1, 12)).not_to include(long)
    end
  end

  describe ".runners_count" do
    let!(:club) { Club.create!(club_name: "Test Club") }
    let!(:category) { Category.create!(category_name: "Test") }

    before do
      3.times { category.runners.create!(club: club) }
    end

    it "filters by runners count range" do
      result = Category
        .left_joins(:runners)
        .group("categories.id")
        .runners_count(2, 4)

      expect(result).to include(category)
    end
  end
end
