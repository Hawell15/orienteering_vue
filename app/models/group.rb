class Group < ApplicationRecord
  belongs_to :competition
  has_many :results, dependent: :destroy

  scope :search, ->(search) {
    left_joins(:competition)
    .where("LOWER(groups.group_name) LIKE :search OR LOWER(competitions.competition_name) LIKE :search", search: "%#{search.downcase}%")
  }

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id group_name competition_name date rang clasa ecn_coeficient results_count]
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

  scope :results_count, ->(from, to) do
    having("COUNT(results.id) BETWEEN ? AND ?", from.to_i, to.to_i)
  end

  scope :date, ->(from, to) {
    left_joins(:competition).where("competitions.date" => from..to)
  }
end
