class Membership < ApplicationRecord
  belongs_to :runner
  belongs_to :club
  has_many :results


  scope :search, ->(search) {
    left_joins(:runner, :club)
    .where("LOWER(CONCAT(runners.runner_name, \' \', runners.surname)) LIKE :search OR LOWER(CONCAT(runners.surname, \' \', runners.runner_name)) LIKE :search OR LOWER(clubs.club_name) LIKE :search", search: "%#{search.downcase}%")
  }

  scope :sorting, ->(sort_by, direction) {
    dir = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"
    order("#{sort_by} #{dir}")
  }

  scope :club_id, ->(val) {
    case val.to_s
    when "all" then all
    else where(club_id: val)
    end
  }

  scope :runner_id, ->(val) {
    case val.to_s
    when "all" then all
    else where(runner_id: val)
    end
  }

  scope :results_count, ->(from, to) do
    scope = left_joins(:results)
            .group("memberships.id")

    if from.present? && to.present?
      scope.having("COUNT(results.id) BETWEEN ? AND ?", from, to)
    elsif from.present?
      scope.having("COUNT(results.id) >= ?". from)
    elsif to.present?
      scope.having("COUNT(results.id) <= ?", to)
    else
      scope
    end
  end
end
