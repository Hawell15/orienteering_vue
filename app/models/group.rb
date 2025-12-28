class Group < ApplicationRecord
  belongs_to :competition
  has_many :results, dependent: :destroy

  scope :sorting, ->(sort_by, direction) {
    dir = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"
    order("#{sort_by} #{dir}")
  }

  scope :search, ->(search) {
    left_joins(:competition)
    .where("LOWER(groups.group_name) LIKE :search OR LOWER(competitions.competition_name) LIKE :search", search: "%#{search.downcase}%")
  }

  scope :competition_id, ->(val) {
    case val.to_s
    when "all" then all
    else where(competition_id: val)
    end
  }

  scope :results_count, ->(from, to) {
    left_joins(:results)
    .group("groups.id").having("COUNT(results.id) BETWEEN ? AND ?", from, to)
  }

  scope :date, ->(from, to) {
    left_joins(:competition).where("competitions.date" => from..to)
  }
end
