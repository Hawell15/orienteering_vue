require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:runners) }
    it { is_expected.to have_many(:results) }
  end

  describe "constants" do
    it "defines NO_CATEGORY_ID" do
      expect(Category::NO_CATEGORY_ID).to eq(10)
    end
  end

  describe "default values" do
    it "sets validaty_period to 2 by default" do
      category = Category.create!(category_name: "Test")
      expect(category.validaty_period).to eq(2)
    end
  end

  describe ".sorting" do
    let!(:cat1) { Category.create!(category_name: "A", points: 10, validaty_period: 5) }
    let!(:cat2) { Category.create!(category_name: "B", points: 20, validaty_period: 3) }
    let(:ids)  { [ cat1.id, cat2.id ] }

    it "sorts by allowed column asc" do
      expect(Category.sorting("points", "asc").where(id: ids)).to eq([ cat1, cat2 ])
    end

    it "sorts by allowed column desc" do
      expect(Category.sorting("points", "desc").where(id: ids)).to eq([ cat2, cat1 ])
    end

    it "sorts by category_name" do
      expect(Category.sorting("category_name", "asc").where(id: ids)).to eq([ cat1, cat2 ])
    end

    it "sorts by validaty_period" do
      expect(Category.sorting("validaty_period", "asc").where(id: ids)).to eq([ cat2, cat1 ])
    end

    it "sorts by created_at" do
      expect(Category.sorting("created_at", "asc").where(id: ids).to_a).to eq([ cat1, cat2 ])
    end

    it "falls back to id for invalid column" do
      expect(Category.sorting("hack", "asc")).to eq(Category.order("id asc"))
    end

    it "falls back to asc for invalid direction" do
      expect(Category.sorting("points", "hack").where(id: ids)).to eq([ cat1, cat2 ])
    end

    it "is case-insensitive for direction" do
      expect(Category.sorting("points", "DESC").where(id: ids)).to eq([ cat2, cat1 ])
    end
  end

  describe ".search" do
    let!(:cat1) { Category.create!(category_name: "Junior", full_name: "Junior category") }
    let!(:cat2) { Category.create!(category_name: "Senior", full_name: "Senior category") }

    it "finds by category_name (case-insensitive)" do
      expect(Category.search("jun")).to include(cat1)
      expect(Category.search("jun")).not_to include(cat2)
    end

    it "finds by full_name (case-insensitive)" do
      expect(Category.search("senior")).to include(cat2)
      expect(Category.search("senior")).not_to include(cat1)
    end

    it "finds by partial match" do
      expect(Category.search("category")).to include(cat1, cat2)
    end

    it "handles mixed case input" do
      expect(Category.search("JUNIOR")).to include(cat1)
    end

    it "returns empty relation when no match" do
      expect(Category.search("zzz")).to be_empty
    end
  end

  describe ".age" do
    let!(:senior) { Category.find_or_create_by!(id: 1) { |c| c.category_name = "Senior" } }
    let!(:junior) { Category.find_or_create_by!(id: 7) { |c| c.category_name = "Junior" } }

    it "returns senior categories (ids 1-6 and 10)" do
      expect(Category.age("senior")).to include(senior)
      expect(Category.age("senior")).not_to include(junior)
    end

    it "returns junior categories (ids 7-10)" do
      expect(Category.age("junior")).to include(junior)
      expect(Category.age("junior")).not_to include(senior)
    end

    it "is case-insensitive" do
      expect(Category.age("SENIOR")).to include(senior)
      expect(Category.age("Junior")).to include(junior)
    end

    it "returns all for unknown value" do
      expect(Category.age("unknown")).to match_array(Category.all)
    end

    it "includes id 10 in both senior and junior" do
      no_cat = Category.find_or_create_by!(id: 10) { |c| c.category_name = "No Category" }
      expect(Category.age("senior")).to include(no_cat)
      expect(Category.age("junior")).to include(no_cat)
    end
  end

  describe ".points" do
    let!(:low)  { Category.create!(points: 5) }
    let!(:mid)  { Category.create!(points: 15) }
    let!(:high) { Category.create!(points: 50) }

    it "filters by points range" do
      expect(Category.points(1, 10)).to include(low)
      expect(Category.points(1, 10)).not_to include(mid, high)
    end

    it "includes boundary values" do
      expect(Category.points(5, 15)).to include(low, mid)
      expect(Category.points(5, 15)).not_to include(high)
    end

    it "converts string params to integers" do
      expect(Category.points("1", "10")).to include(low)
      expect(Category.points("1", "10")).not_to include(mid, high)
    end
  end

  describe ".validaty_period" do
    let!(:short) { Category.create!(validaty_period: 6) }
    let!(:long)  { Category.create!(validaty_period: 24) }

    it "filters by validaty_period range" do
      expect(Category.validaty_period(1, 12)).to include(short)
      expect(Category.validaty_period(1, 12)).not_to include(long)
    end

    it "includes boundary values" do
      expect(Category.validaty_period(6, 24)).to include(short, long)
    end

    it "converts string params to integers" do
      expect(Category.validaty_period("1", "12")).to include(short)
      expect(Category.validaty_period("1", "12")).not_to include(long)
    end
  end

  describe ".runners_count" do
    let!(:club) { Club.create!(club_name: "Test Club") }
    let!(:popular_category) { Category.create!(category_name: "Popular") }
    let!(:empty_category) { Category.create!(category_name: "Empty") }

    before do
      3.times { popular_category.runners.create!(club: club) }
    end

    it "filters categories within runners count range" do
      result = Category
        .left_joins(:runners)
        .group("categories.id")
        .runners_count(2, 4)

      expect(result).to include(popular_category)
      expect(result).not_to include(empty_category)
    end

    it "excludes categories outside runners count range" do
      result = Category
        .left_joins(:runners)
        .group("categories.id")
        .runners_count(5, 10)

      expect(result).not_to include(popular_category)
    end

    it "converts string params to integers" do
      result = Category
        .left_joins(:runners)
        .group("categories.id")
        .runners_count("2", "4")

      expect(result).to include(popular_category)
    end
  end
end
