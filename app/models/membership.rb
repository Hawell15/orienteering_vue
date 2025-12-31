class Membership < ApplicationRecord
  belongs_to :runner
  belongs_to :club
  has_many :results


  scope :search, ->(search) {
    left_joins(:runner, :club)
    .where("LOWER(CONCAT(runners.runner_name, \' \', runners.surname)) LIKE :search OR LOWER(CONCAT(runners.surname, \' \', runners.runner_name)) LIKE :search OR LOWER(clubs.club_name) LIKE :search", search: "%#{search.downcase}%")
  }

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id club_name full_name results_count]
    column          = allowed_columns.include?(sort_by) ? sort_by : "id"
    direction       = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"

    order("#{column} #{direction}")
  }

  scope :club, ->(val) {
    case val.to_s
    when "all" then all
    else where(club_id: val)
    end
  }

  scope :runner, ->(val) {
    case val.to_s
    when "all" then all
    else where(runner_id: val)
    end
  }

  scope :results_count, ->(from, to) do
    having("COUNT(results.id) BETWEEN ? AND ?", from.to_i, to.to_i)
  end
end
