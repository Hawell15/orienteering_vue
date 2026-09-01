class Group < ApplicationRecord
  THREE_RESULTS_GROUP_ID              = 1346
  REDUCTION_CATEGORY_GROUP_ID         = 2
  TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID = 2667
  NO_GROUP_ID                         = 1

  belongs_to :competition
  has_many :results, dependent: :destroy
  has_many :relay_results, dependent: :destroy

  after_update :clear_ecn_points, if: -> { saved_change_to_ecn_coeficient? && ecn_coeficient.zero? }

  before_validation :pretify_group_name

  scope :search, ->(val) {
    left_joins(:competition)
    .where("LOWER(groups.group_name) LIKE :search OR LOWER(competitions.competition_name) LIKE :search", search: "%#{val.downcase}%")
  }

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id group_name competition_name date rang clasa ecn_coeficient results_count created_at]
    column          = allowed_columns.include?(sort_by) ? sort_by : "id"
    direction       = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"

    order("#{column} #{direction}")
  }

  scope :competition, ->(val) {
    case val.to_s
    when "all" then all
    else where(competition_id: val)
    end
  }

  scope :clasa, ->(val) {
    case val.to_s
    when "all" then all
    else where(clasa: val)
    end
  }

  scope :results_count, ->(from, to) {
    having("COUNT(results.id) BETWEEN ? AND ?", from.to_i, to.to_i)
  }

  scope :date, ->(from, to) {
    left_joins(:competition).where("competitions.date" => from..to)
  }


  def self.normalize_group_name(name)
    name.upcase.remove(" ").sub("М", "M").sub("Ж", "W")
  end

  def self.add_group(params)
    params = params.with_indifferent_access
    return Group.find(params["group_id"]) if params["group_id"]

    Group.find_or_create_by(params)
  end

  private

  def clear_ecn_points
    results.update_all(ecn_points: 0.0)
  end

  def pretify_group_name
    self.group_name = self.class.normalize_group_name(self.group_name)
  end
end
