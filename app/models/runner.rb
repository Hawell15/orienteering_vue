class Runner < ApplicationRecord
  belongs_to :club
  belongs_to :category
  belongs_to :best_category, class_name: "Category"
  has_many :memberships, dependent: :destroy
  has_many :results, through: :memberships

  before_save :add_checksum

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[
      id full_name category_id category_valid gender yob club_name best_category_id wre_id sprint_wre_place forest_wre_place created_at
    ]

    column    = allowed_columns.include?(sort_by) ? sort_by : "id"
    direction = %w[asc desc].include?(direction.to_s.downcase) ? direction : "desc"
    order("#{column} #{direction}")
  }

  scope :club, ->(val) {
    case val.to_s
    when "all" then all
    else where(club_id: val)
    end
  }

  scope :membership, ->(val) {
    case val.to_s
    when "all" then all
    else joins(:memberships).where("memberships.club_id": val)
    end
  }

  scope :category, ->(val) {
    case val.to_s
    when "all" then all
    else where(category_id: val)
    end
  }

  scope :best_category, ->(val) {
    case val.to_s
    when "all" then all
    else where(best_category: val)
    end
  }

  scope :gender, ->(val) {
    case val.to_s
    when "all" then all
    else where(gender: val)
    end
  }

  scope :wre, -> { where.not(wre_id: nil) }
  scope :yob, ->(from, to) { where yob: from..to }

  scope :matching_runner, lambda { |options|
    where("wre_id = :wre_id or id = :id or checksum = :checksum",
          wre_id: options[:wre_id],
          id: options[:id],
          checksum: get_checksum(*options.values_at("runner_name", "surname", "yob", "gender")))
  }

  def self.add_runner(params, skip_matching = false)
    params = params.with_indifferent_access

    params["runner_name"] = RussianConversion.convert_from_russian(params["runner_name"].downcase).titlecase
    params["surname"]     = RussianConversion.convert_from_russian(params["surname"].downcase).titlecase

    runner = matching_runner(params).first
    update_yob(runner, params[:yob])

    runner ||= RunnerMatching.get_runner_by_matching(params) unless skip_matching
    params["id"] ||= (Runner.maximum(:id) || 0) + 1
    runner ||= Runner.create!(params.except("category_id", "date"))

    runner
  end

  def category_on_date(date = Date.today)
    results
      .joins(:category, :runner)
      .joins(:runner)
      .where(status: Result::CONFIRMED)
      .where("results.date <= :date", date: date)
      .where.not("results.category_id = ?", Category::NO_CATEGORY_ID)
      .where("results.date + (categories.validaty_period * INTERVAL '1 year') > :date", date: date)
      .where(
        "NOT (categories.id BETWEEN 7 AND 9 AND runners.yob <= EXTRACT(YEAR FROM :date::date) - 18)",
        date: date
      )
      .order(:category_id, date: :desc)
      .first
  end

  def update_runner_category(date = Date.today)
    result = category_on_date(date)

    attrs = {
      best_category_id: [ best_category_id, result&.category_id ].compact.min || Category::NO_CATEGORY_ID,
      category_id:      result&.category_id || Category::NO_CATEGORY_ID,
      category_valid:   result ? (result.date + result.category.validaty_period.years) : Date.new(2100, 1, 1)
    }

    assign_attributes(attrs)
    save! if changed?
  end

  private

  def add_checksum
    self.checksum = self.class.get_checksum(runner_name, surname, yob, gender)
  end

  def self.get_checksum(runner_name, surname, yob, gender)
    (Digest::SHA2.new << "#{runner_name}-#{surname}-#{yob}-#{gender}").to_s
  end

  def junior_runner?
    Time.now.year - yob.year < 18
  end

  def self.update_yob(runner, yob)
    return unless runner.yob.zero?
    return if yob.blank? || yob.zero?

    runner.update!(yob: yob)
  end
end
